# Guide rapide – Comment contribuer à dbt via une Merge Request

Bonjour Camille 👋

Tu peux contribuer à un modèle dbt **sans utiliser le terminal**. Le plus simple est de passer par l’éditeur web ou l’IDE de dbt / GitLab, puis d’envoyer une **Merge Request (MR)**. Une MR, c’est simplement une **demande de relecture** avant que ton changement soit ajouté au projet principal. 

## Le principe en 5 étapes

### 1. Ouvre le projet et trouve le bon fichier
Va dans le projet dbt, puis ouvre le fichier à modifier :
- soit un modèle SQL (`.sql`)
- soit un fichier de documentation/tests (`.yml`)

Travaille toujours sur **ton propre brouillon**, pas directement sur la version principale du projet. En pratique, cela se fait avec une **branche** créée pour ton changement. dbt Studio et GitLab permettent de créer ou changer de branche depuis l’interface. 

### 2. Fais un changement petit et clair
Exemple :
- corriger un filtre,
- ajouter une colonne,
- améliorer un nom,
- compléter une description,
- ajouter un test simple.

Évite de mélanger plusieurs sujets dans la même MR. Une petite MR est plus facile à relire, tester et valider.

### 3. Enregistre avec un message simple
Quand ton changement est prêt, **commit** tes modifications avec un message court qui explique ce que tu as fait.

Exemples :
- `ajoute le test not_null sur booking_id`
- `corrige le filtre sur les devis annulés`
- `documente la colonne revenue_amount`

Dans dbt Studio, tu peux créer une PR/MR après avoir commit ; dans GitLab Web IDE aussi, l’option apparaît juste après le commit.

### 4. Crée la Merge Request
Crée ensuite une **Merge Request** depuis ta branche vers la branche principale du projet.

Dans la MR, indique :
- **ce que tu as changé**
- **pourquoi**
- **ce qu’il faut vérifier**

Exemple :

**Titre**  
`Corrige le calcul du revenue net sur les devis post-stay`

**Description**  
- correction d’un filtre SQL  
- pas de changement attendu sur le grain  
- vérifier les montants Finance sur mars 2026

GitLab permet de créer une MR depuis l’interface projet ou directement après un commit dans le Web IDE.

### 5. Attends la relecture et répond aux commentaires
La MR sera relue par quelqu’un de l’équipe. La personne peut :
- approuver,
- poser des questions,
- demander une petite correction.

C’est normal. Une MR sert justement à **discuter avant mise en production**. Les plateformes de code permettent ensuite de revoir les fichiers modifiés et de commenter directement dessus. 

## Les 4 réflexes à garder

- **Fais simple** : une MR = un seul sujet.
- **Explique le besoin métier** : pas seulement le SQL, mais aussi l’impact.
- **Relis ce que tu as changé** avant d’envoyer.
- **Demande de l’aide tôt** si tu hésites sur le bon fichier ou la bonne logique.

## Modèle très simple pour ta MR

**Titre**  
`[Sales] correction / ajout sur <nom du modèle>`

**Description**  
- Contexte :  
- Changement effectué :  
- Impact attendu :  
- Point à vérifier par le reviewer :

## À retenir
Tu n’as pas besoin d’être experte Git pour contribuer. Ton objectif est simplement :
1. modifier le bon fichier,
2. enregistrer ton changement dans une branche,
3. ouvrir une MR,
4. expliquer clairement ton intention.

Le reste se fait avec la relecture de l’équipe.