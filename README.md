# Naboo Data Engineering — Test Technique

Ce dépôt contient la modélisation **dbt** réalisée pour le test technique Naboo.

L'objectif du projet est de structurer les données issues des demandes, propositions, devis et lignes tarifaires afin de produire une **table de faits fiable pour l’équipe Finance** : `fct_event_revenue`.

Cette table permet d’analyser les revenus générés par un événement **par proposition commerciale et par prestataire**.

Le projet est organisé selon une architecture dbt classique en **trois couches : staging, intermediate et marts**, permettant de transformer progressivement les données sources en un modèle analytique robuste.

---
# 🔍 Partie 0 — Analyse exploratoire des données

Cette section présente les observations issues de l'exploration des données sources fournies dans le test technique.
L'objectif est de comprendre :

* le **grain des tables**
* les **relations entre entités**
* les **types de lignes économiques**
* les **anomalies de qualité de données**
* les implications pour la modélisation analytique.

---

# 0.1 — Quel est le grain de chaque table ?

Le grain correspond à l’unité logique représentée par une ligne dans la table.

| Table                  | Nombre de lignes | Grain identifié                                         |
| ---------------------- | ---------------- | ------------------------------------------------------- |
| `client_requests`      | 3                | 1 demande client                                        |
| `client_proposals`     | 4                | 1 proposition commerciale pour une demande et une house |
| `quotes`               | 6                | 1 devis ou étape de paiement                            |
| `client_pricing_items` | 32               | 1 ligne tarifaire                                       |

Observations :

* une **demande peut générer plusieurs propositions**
* une **demande peut générer plusieurs devis**
* un **devis peut contenir plusieurs lignes tarifaires**

Exemples observés :

* `req-001` possède **2 propositions**
* `req-001` possède **4 quotes**
* un `quote_id` peut avoir **plusieurs pricing items**

---

# 0.2 — Quelles sont les relations entre les tables ?

## Relation : `client_requests → client_proposals`

Type : **1:N**

Clé :

    client_proposals.client_request_id
    → client_requests.request_id

Une demande peut donner lieu à plusieurs propositions commerciales, généralement pour différentes venues (`house_id`).

---

## Relation : `client_requests → quotes`

Type : **1:N**

Clé :

    quotes.client_request_id
    → client_requests.request_id

Une demande client peut générer plusieurs devis correspondant à différentes étapes de paiement ou propositions commerciales.

---

## Relation : `quotes → client_pricing_items`

Type : **1:N**

Clé :

    client_pricing_items.quote_id
    → quotes.quote_id

Un devis (`quote`) est composé de plusieurs lignes tarifaires (`pricing_items`) représentant les différentes prestations et frais associés.

Observation :

* 31 lignes sur 32 correspondent à un `quote_id` existant.
* 1 ligne (`pi-orphan`) référence un `quote_id` inexistant (`q-orphan`).

Cela constitue une **anomalie de qualité de données**.

---

## Relation : `client_proposals → quotes`

Cette relation est **indirecte**.

Les propositions référencent les quotes via les colonnes :

    deposit_quote_ids
    balance_quote_ids
    balance_post_stay_quote_ids

Ces colonnes contiennent des **listes d'identifiants de devis**.

Cela implique qu’une proposition peut référencer **plusieurs quotes correspondant aux différentes étapes de paiement**.

# Diagramme

```text
                    client_requests
                           │
           ┌───────────────┴───────────────┐
           │                               │
           ▼                               ▼
   client_proposals                    quotes
           │                               │
           │                               ▼
           │                        client_pricing_items
           │
           └──── references quotes
                via quote_ids lists
```


Interprétation métier :

1. Une **entreprise soumet une demande** (`client_requests`)
2. Naboo propose **plusieurs lieux / propositions** (`client_proposals`)
3. Chaque proposition peut générer **plusieurs devis** (`quotes`)
4. Chaque devis contient **plusieurs lignes tarifaires** (`client_pricing_items`)
   

---

# 0.3 — Quels types de lignes existent dans `client_pricing_items` ?

Trois types principaux apparaissent dans les données.

| type       | category                        | interprétation             |
| ---------- | ------------------------------- | -------------------------- |
| AD_HOC     | HOUSE / RESTAURATION / ACTIVITE | prestations vendues        |
| USER_FEES  | FEES                            | frais facturés au client   |
| OWNER_FEES | FEES                            | commission côté partenaire |

Les lignes `AD_HOC` représentent les services réellement vendus dans le cadre de l’événement.

Les lignes :

* `USER_FEES`
* `OWNER_FEES`

correspondent aux frais de plateforme Naboo.

Cette distinction est essentielle pour construire les métriques de revenus.

---

# 0.4 — Comment gérer les différentes versions de devis ?

La colonne :

    deposit_status

indique le stade commercial du devis.

Valeurs observées :

    INITIAL
    FINAL
    POST_FINAL

Les mêmes prestations peuvent apparaître à plusieurs stades.

Par exemple :

* un devis peut être créé (`INITIAL`)
* puis ajusté (`FINAL`)
* puis ajusté après l'événement (`POST_FINAL`)

Si l'on additionne toutes les lignes, cela provoquerait un **double comptage des revenus**.

La modélisation devra donc sélectionner **une seule version du devis**.

---

# 0.5 — Comment sont stockés les montants et les taux ?

### Montants

Les montants sont stockés dans les colonnes :

    total_price_base_price_price_without_vat
    total_price_base_price_price_with_vat

Ils sont cohérents avec une précision monétaire standard de **2 décimales**.

---

### Taux

Les taux sont stockés sous forme de **micro-taux** :

    valeur_stockée = taux × 1 000 000

Exemple :

    70000 = 7 %

Ces taux doivent être **divisés par 1 000 000** dans le modèle staging.

---

# 0.6 — Comment relier `client_pricing_items` aux propositions ?

La colonne :

    client_proposal_id

n’est pas fiable.

Observation :

* **81 % des lignes ne possèdent pas de `client_proposal_id`**

Cette colonne ne peut donc pas être utilisée comme clé de jointure principale.

Le lien réel est :

    client_proposals
        └─ references quotes via quote_id lists
    
    quotes
        └─ contains client_pricing_items

La modélisation devra donc reconstruire explicitement ce mapping.

---

# 0.7 — Quelles anomalies de données ont été détectées ?

Plusieurs anomalies apparaissent dans les données sources :

### Pricing item orphelin

    pi-orphan
    → quote_id = q-orphan

Ce quote n’existe pas dans `quotes`.

---

### Ligne supprimée

Certaines lignes possèdent :

    deleted = true

Elles doivent être exclues.

---

### Quantité nulle

Certaines lignes présentent :

    quantity = 0
    mais prix élevé

Ce type de ligne doit être surveillé.

---

### Quote utilisé pour plusieurs rôles

Exemple :

    q-005
    utilisé pour deposit et balance

Cela peut provoquer des incohérences si non géré.

---

# Conclusion de l'exploration

L’exploration met en évidence plusieurs implications importantes pour la modélisation :

1️⃣ le lien entre propositions et pricing items doit être **reconstruit via les quotes**

2️⃣ les devis existent sous **plusieurs versions**

3️⃣ les lignes tarifaires contiennent **plusieurs types économiques**

4️⃣ certaines anomalies doivent être **filtrées ou signalées**

Ces constats orientent directement les choix de modélisation décrits dans la **Partie 1 : Architecture dbt**.

---

# 🏗️ Partie 1 : Architecture dbt (Choix et Arbitrages)

L’architecture du projet suit une séparation classique en **trois couches dbt** :

    staging
    intermediate
    marts

Ce découpage permet de séparer :

1️⃣ **la préparation des données sources**

2️⃣ **la reconstruction des relations métier**

3️⃣ **l'exposition des tables analytiques**

---

# 📊 Modèle relationnel cible

Le système source ne fournit pas directement un modèle relationnel exploitable pour l’analyse.
En particulier, les propositions référencent les devis via **des listes d’identifiants**, ce qui empêche de reconstruire facilement les relations analytiques.

L’objectif est donc de **reconstruire un modèle relationnel cohérent** permettant d’analyser les revenus par événement et par prestataire.

Le modèle cible est le suivant :

```text
client_requests
        │
        │ 1:N
        ▼
client_proposals
        │
        │ 1:N
        ▼
quotes
        │
        │ 1:N
        ▼
client_pricing_items
```

La couche **intermediate** du projet dbt a pour rôle de **reconstruire explicitement ces relations** à partir des données sources.

---

# 1. Couche Staging

    models/staging/

Les modèles staging préparent les données sources **table par table**.

Matérialisation :

    view

### Objectifs

* nettoyer les données
* normaliser les formats
* documenter les colonnes

### Transformations appliquées

Filtrage :

    where deleted = false

Normalisation :

    upper(status)
    upper(type)
    upper(category)

Conversion des micro-taux :

    rate / 1_000_000

### Modèles staging

    stg_client_requests
    stg_client_proposals
    stg_quotes
    stg_client_pricing_items

### Pourquoi garder le staging simple ?

La couche staging **ne reconstruit pas les relations complexes**.
Par exemple, le lien `client_proposals ↔ pricing_items` passe par `quotes` et nécessite un dépivotage. Il est donc traité dans la couche suivante.

---

# 2. Couche Intermediate

    models/intermediate/

Cette couche est le **cœur du modèle analytique**. Elle résout deux problèmes majeurs :

1️⃣ reconstruire les relations entre entités
2️⃣ éviter les doubles comptages liés aux versions de devis

---

# Reconstruction du mapping métier & Stratégie de Quarantaine

Les propositions référencent des devis via des listes d'identifiants (`deposit_quote_ids`, etc.).

Le modèle `int_proposal_quotes` dépivote ces listes pour obtenir :
    1 ligne = 1 proposition × 1 quote × 1 rôle

Afin d'isoler les anomalies détectées (ex: un quote rattaché au mauvais rôle), un **pattern de quarantaine** a été implémenté :
* `int_proposal_quotes_valid` : conserve uniquement les relations saines (ex: `is_quote_role_consistent = true`).
* `int_proposal_quotes_quarantine` : isole les enregistrements incohérents pour faciliter l'investigation sans bloquer le modèle de bout en bout.

---

# Bridge entre propositions et pricing items

Le modèle `int_proposal_quote_pricing_items` rattache les lignes tarifaires aux propositions via les quotes *valides*.
Le grain devient :
    1 proposition × 1 quote × 1 pricing_item

---

# Gestion du stade de facturation et des snapshots

Pour éviter le double comptage, le pipeline sélectionne **le quote le plus avancé** et **le snapshot tarifaire le plus récent**.

* `dim_quote_stage` identifie, pour chaque proposition et pour chaque rôle de quote (`DEPOSIT`, `BALANCE`, `POST_BALANCE`), le quote courant retenu, en priorisant la cohérence métier, puis le statut `WON`, puis le plus récent.
* `int_current_quote_pricing_items` prend ce quote courant retenu et conserve, pour ses lignes tarifaires, le snapshot tarifaire le plus avancé. (`POST_FINAL > FINAL > INITIAL`).

---

# Décomposition des composants de revenu

Le modèle `int_pricing_item_revenue_components` traduit les lignes tarifaires en composants économiques (montant prestation, frais client, commission, etc.) à la maille ligne tarifaire.

---

# 3. Couche Marts

    models/marts/

Expose les tables analytiques finales, en séparant la pré-agrégation de l'exposition finale.

---

# Pré-agrégation et Table de faits finale

La modélisation finale s'effectue en deux temps :

1️⃣ **`pre_fct_event_revenue`** :
Agrège les métriques financières au grain `1 ligne = 1 quote_stage_key × 1 service_owner_id`. Ce modèle expose les revenus pour *tous les stades de facturation existants* d'une proposition.

2️⃣ **`fct_event_revenue`** :
C'est la table exposée aux utilisateurs métier (Finance). Elle filtre les données pré-agrégées pour ne retenir **que le stade le plus récent** atteint par la proposition (basé sur le `billing_stage_rank` et la date de création du devis).
Le grain final est bien : `1 ligne = 1 proposition × 1 prestataire`.

---

# 📊 Partie 2 : Modèle de Revenus

La table finale calcule les métriques suivantes par événement et partenaire :

| Métrique               | Colonne                    |
| ---------------------- | -------------------------- |
| GMV net                | `gmv_service_net`          |
| GMV brut               | `gmv_with_client_fees`     |
| Montant brut (service) | `service_gross_amount`     |
| Frais Naboo            | `naboo_client_fees`        |
| Commission Naboo       | `naboo_partner_commission` |
| Marge totale           | `total_margin`             |
| Part partenaire        | `supplier_net_payout`      |
| Remise totale          | `total_discount`           |

---

# Règles de calcul

Toutes les métriques sont calculées sur :
* le **quote le plus avancé**
* le **snapshot tarifaire le plus récent**

Exemple de logique économique validée dans le modèle :
GMV brut : `GMV net + Frais client`
Marge totale : `Frais client + Commission partenaire`
Part partenaire : `GMV net - Commission partenaire`

---

# 🔎 Data Quality et tests dbt

Afin de garantir la fiabilité du modèle analytique, une batterie de **tests de qualité dbt** a été mise en place, allant de l'intégrité structurelle à la cohérence comptable experte.

---

# Types de tests utilisés

## Tests structurels et référentiels
* `not_null` et `unique` sur les clés générées (ex: `event_revenue_key`).
* `relationships` pour garantir que chaque dimension ou pont fait référence à des IDs existants (`stg_client_proposals`, `stg_quotes`, etc.).
* `accepted_values` sur les statuts normalisés (`DEPOSIT`, `BALANCE`, `POST_BALANCE`).

## Tests de cohérence métier à la ligne
* **Prix TTC supérieur au prix HT** : `price_with_vat >= price_without_vat`
* **Cohérence des typologies** : Par exemple, s'assurer que des frais de service n'ont pas de remises associées (`pricing_type != 'USER_FEES' or discount_amount = 0`).

## Tests de cohérence comptable sur la fact table
La table `pre_fct_event_revenue` et `fct_event_revenue` incluent des vérifications macro économiques strictes :

    # Marge totale = commission + frais client
    expression: "total_margin = naboo_client_fees + naboo_partner_commission"
    
    # Payout fournisseur = GMV net - commission partenaire
    expression: "supplier_net_payout = gmv_service_net - naboo_partner_commission"

**Gestion des arrondis (Floats)** :
Pour les contrôles impliquant des remises et des montants bruts, une tolérance d'arrondi a été implémentée pour éviter de faire échouer le pipeline pour des écarts de micro-centimes générés par les calculs SQL :

    expression: "abs(service_gross_amount - (gmv_service_net + total_discount)) < 0.01"

## Indicateurs (Flags) de qualité de données
Certaines incohérences ne sont pas bloquantes mais doivent être traçables par l'équipe Data. Des colonnes booléennes (`is_quote_role_consistent`, `has_data_quality_issue`) sont poussées jusqu'à la couche Marts pour permettre la création de dashboards de monitoring de la Data Quality.

---

# Résumé

Le projet met en place :
* une **architecture modulaire dbt**
* une **reconstruction explicite** avec un pattern de **quarantaine** pour isoler les données corrompues.
* une séparation claire entre la **pré-agrégation** de tous les stades (`pre_fct_event_revenue`) et le filtrage sur le **stade de facturation final** (`fct_event_revenue`).
* une **stratégie de qualité de données stricte** garantissant que chaque centime est justifié.