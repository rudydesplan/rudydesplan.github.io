# Partie 3 — Anomalies observées

## Anomalie observée

Dans `client_pricing_items`, les colonnes monétaires :

- `total_price_base_price_price_without_vat`
- `total_price_base_price_price_with_vat`

sont stockées en `FLOAT64` et non dans un type décimal exact.

Lors de l’exploration des données, certaines valeurs apparaissent en notation scientifique, par exemple `1.2E8`, `8.0E7` ou `1.44E7`. 

Le point important est que **la notation scientifique n’est pas l’anomalie en soi** : c’est seulement une manière d’afficher un nombre flottant.  
Le vrai sujet est que des **montants financiers** sont modélisés avec un **type flottant**, ce qui peut introduire des imprécisions de calcul.

## Impact potentiel sur les calculs

Utiliser `FLOAT64` pour des montants peut produire :

- des erreurs d’arrondi dans les agrégations (`SUM`, `AVG`, marges, GMV, commissions),
- des écarts lors des comparaisons d’égalité,
- des incohérences entre montants recalculés et montants stockés,
- des écarts cumulés dans les dashboards financiers ou KPI de revenu.

Même si le jeu de données d’exemple semble “propre”, ce choix de type devient risqué en production dès que les volumes augmentent ou que plusieurs transformations s’enchaînent.

## Comment le détecter automatiquement en production

### 1. Contrôle de schéma
Mettre en place un contrôle automatique pour vérifier que les colonnes monétaires n’utilisent pas `FLOAT64` mais un type décimal exact (`NUMERIC` / `BIGNUMERIC` selon le besoin).

### 2. Test d’intégrité sur les décimales
Vérifier que les montants respectent une précision monétaire attendue, par exemple 2 décimales maximum.

Exemple de règle :
- `round(montant, 2) = montant`

### 3. Test de cohérence de calcul
Comparer des montants dérivés à partir des taux et des bases de prix avec les montants stockés, avec une tolérance très faible.
Cela permet de détecter des dérives dues à la précision flottante.

### 4. Alerte sur dérive d’agrégats
Surveiller dans le temps les écarts entre :
- GMV recalculé,
- frais recalculés,
- montants facturés agrégés.

Une différence faible mais récurrente peut signaler un problème de précision numérique.

## Recommandation

Dans le modèle de staging ou dans la couche de transformation, caster les colonnes monétaires vers un type décimal exact adapté aux usages financiers, afin de fiabiliser les calculs analytiques.