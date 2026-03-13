stg_client_requests_schema.yml :

version: 2

models:
  - name: stg_client_requests
    description: "Demandes clients nettoyées au grain 1 ligne = 1 client_request. Les lignes supprimées sont exclues, le statut est normalisé en majuscules et le nombre de participants correspond au nombre d'adultes."

    tests:       
      - dbt_utils.expression_is_true:
          expression: "client_request_status = upper(client_request_status)"
          
      - dbt_utils.recency:
          field: client_request_created_at
          datepart: year
          interval: 5

    columns:
      - name: client_request_key
        description: "Clé technique générée via hash à partir de request_id."
        tests:
          - not_null
          - unique
    
      - name: client_request_id
        description: "Identifiant métier unique de la demande client."
        tests:
          - not_null
          - unique

      - name: client_request_company_id
        description: "Identifiant de l'entreprise ayant soumis la demande."
        tests:
          - not_null

      - name: client_request_company_name
        description: "Nom de l'entreprise ayant soumis la demande."
        tests:
          - dbt_utils.not_empty_string

      - name: client_request_status
        description: "Statut de la demande normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['CONFIRMED', 'IN_PROGRESS']

      - name: client_request_created_at
        description: "Horodatage de création de la demande."
        tests:
          - not_null

      - name: client_request_participants_count
        description: "Nombre d'adultes demandés dans la requête."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
          
      - name: _loaded_at
        description: "Timestamp technique indiquant quand la ligne a été chargée par dbt."
        tests:
          - not_null

stg_client_proposals_schema.yml  :

version: 2

models:
  - name: stg_client_proposals
    description: "Propositions commerciales nettoyées au grain 1 ligne = 1 proposition. Les lignes supprimées sont exclues. Les identifiants de quotes sont conservés tels quels afin de reconstruire le mapping proposal ↔ quote dans un modèle intermédiaire."

    tests:
      - dbt_utils.expression_is_true:
          expression: "client_proposal_status = upper(client_proposal_status)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_start_at <= client_proposal_end_at"

    columns:
      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - unique

      - name: client_request_id
        description: "Identifiant de la demande client associée à la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_requests')
              field: client_request_id

      - name: client_proposal_house_id
        description: "Identifiant de la venue proposée."
        tests:
          - not_null

      - name: client_proposal_status
        description: "Statut de la proposition normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['PUBLISHED', 'BOOKING_CONFIRMED']

      - name: client_proposal_deposit_rate
        description: "Taux d'acompte normalisé en ratio décimal (valeur source divisée par 1 000 000)."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: deposit_quote_ids
        description: "Liste brute des identifiants de quotes d'acompte."

      - name: balance_quote_ids
        description: "Liste brute des identifiants de quotes de solde."

      - name: balance_post_stay_quote_ids
        description: "Liste brute des identifiants de quotes post-séjour."

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre d'adultes prévu dans la proposition."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
        
      - name: _loaded_at
        description: "Timestamp technique indiquant quand la ligne a été chargée par dbt."
        tests:
          - not_null

stg_client_pricing_items_schema.yml  :

version: 2

models:
  - name: stg_client_pricing_items
    description: "Lignes tarifaires nettoyées au grain 1 ligne = 1 pricing_item. Les lignes supprimées sont exclues. Les taux sont normalisés depuis un micro-rate vers un ratio décimal."

    tests:
      - dbt_utils.expression_is_true:
          expression: "pricing_deposit_status = upper(pricing_deposit_status)"

      - dbt_utils.expression_is_true:
          expression: "pricing_type = upper(pricing_type)"

      - dbt_utils.expression_is_true:
          expression: "pricing_category = upper(pricing_category)"

      - dbt_utils.expression_is_true:
          expression: "total_price_base_price_price_with_vat >= total_price_base_price_price_without_vat"

    columns:
      - name: pricing_item_id
        description: "Identifiant unique de la ligne tarifaire."
        tests:
          - not_null
          - unique

      - name: quote_id
        description: "Identifiant du quote parent de la ligne tarifaire."
        tests:
          - not_null

      - name: client_proposal_id
        description: "Valeur source de client_proposal_id conservée à titre informatif uniquement ; la jointure fiable vers les propositions doit passer par quotes."

      - name: service_owner_id
        description: "Identifiant du fournisseur ou du service owner."
        tests:
          - not_null

      - name: pricing_deposit_status
        description: "Statut de paiement de la ligne tarifaire, normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['INITIAL', 'FINAL', 'POST_FINAL']

      - name: pricing_type
        description: "Type métier de la ligne tarifaire (normalisé en majuscules)."
        tests:
          - not_null
          - accepted_values:
              values: ['AD_HOC', 'USER_FEES', 'OWNER_FEES']

      - name: pricing_category
        description: "Catégorie métier de la ligne tarifaire (normalisée en majuscules)."
        tests:
          - not_null
          - accepted_values:
              values: ['FEES', 'ACTIVITE', 'HOUSE', 'RESTAURATION']

      - name: price_option_quantity
        description: "Quantité associée à la ligne tarifaire."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: total_price_base_price_price_without_vat
        description: "Montant HT de la ligne tarifaire."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: total_price_base_price_price_with_vat
        description: "Montant TTC de la ligne tarifaire."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: price_option_user_fees_rate
        description: "Taux de frais utilisateur converti en ratio décimal (valeur source divisée par 1 000 000)."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_owner_fees_rate
        description: "Taux de commission propriétaire converti en ratio décimal (valeur source divisée par 1 000 000)."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_discount_rate
        description: "Taux de remise converti en ratio décimal (valeur source divisée par 1 000 000)."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1
              
      - name: _loaded_at
        description: "Timestamp technique indiquant quand la ligne a été chargée par dbt."
        tests:
          - not_null

stg_quotes_schema.yml  :

version: 2

models:
  - name: stg_quotes
    description: "Quotes nettoyés au grain 1 ligne = 1 quote. Les lignes supprimées sont exclues, les statuts et types de paiement sont normalisés en majuscules et le taux d'acompte est converti depuis un micro-rate."

    tests:
      - dbt_utils.expression_is_true:
          expression: "quote_status = upper(quote_status)"

      - dbt_utils.expression_is_true:
          expression: "quote_payment_type = upper(quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "quote_start_at <= quote_end_at"

      - dbt_utils.recency:
          field: quote_created_at
          datepart: year
          interval: 5

    columns:
      - name: quote_id
        description: "Identifiant unique du quote."
        tests:
          - not_null
          - unique

      - name: client_request_id
        description: "Identifiant de la demande client associée au quote."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_requests')
              field: client_request_id

      - name: quote_house_id
        description: "Identifiant de la venue associée au quote."
        tests:
          - not_null

      - name: quote_payment_type
        description: "Type de paiement du quote normalisé en majuscules (ex : DEPOSIT, BALANCE, POST_STAY)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_STAY']

      - name: quote_status
        description: "Statut du quote normalisé en majuscules  (ex : WON, LOST, PENDING)."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']
        
      - name: quote_deposit_rate
        description: "Taux d'acompte normalisé en ratio décimal (valeur source divisée par 1 000 000)."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: quote_start_at
        description: "Horodatage de début du séjour associé au quote."
        tests:
          - not_null

      - name: quote_end_at
        description: "Horodatage de fin du séjour associé au quote."
        tests:
          - not_null

      - name: quote_created_at
        description: "Horodatage de création du quote."
        tests:
          - not_null
          
      - name: _loaded_at
        description: "Timestamp technique indiquant quand la ligne a été chargée par dbt."
        tests:
          - not_null