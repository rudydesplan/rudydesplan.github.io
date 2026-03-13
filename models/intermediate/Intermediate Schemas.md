dim_quote_stage.yml :

version: 2

models:
  - name: dim_quote_stage
    description: >
      Modèle intermédiaire identifiant pour chaque proposition le quote le plus avancé
      dans le cycle de facturation (DEPOSIT, BALANCE, POST_BALANCE).
      Le grain est : 1 ligne = 1 proposition avec son quote le plus avancé.

    tests:
      - dbt_utils.expression_is_true:
          expression: "billing_stage = upper(billing_stage)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_status = upper(client_proposal_status)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_payment_type = upper(current_quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_status = upper(current_quote_status)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_start_at <= client_proposal_end_at"

      - dbt_utils.expression_is_true:
          expression: "current_quote_start_at <= current_quote_end_at"

      - dbt_utils.expression_is_true:
          expression: "is_billing_stage_known in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_quote_data_quality_issue in (true, false)"

    columns:

      - name: quote_stage_key
        description: "Clé technique générée à partir de client_proposal_id."
        tests:
          - not_null
          - unique

      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - unique
          - relationships:
              to: ref('stg_client_proposals')
              field: client_proposal_id

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

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre de participants prévu dans la proposition."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              
      - name: billing_stage
        description: "Stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage_rank
        description: "Ordre logique du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: billing_stage_label
        description: "Libellé métier du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: ['Deposit', 'Balance', 'Post balance']

      - name: client_proposal_quote_key
        description: "Clé technique du lien proposal ↔ quote issu de int_proposal_quotes."
        tests:
          - not_null
          - relationships:
              to: ref('int_proposal_quotes')
              field: client_proposal_quote_key

      - name: current_quote_id
        description: "Identifiant du quote retenu comme stage courant de la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: current_quote_client_request_id
        description: "Identifiant de la demande client côté quote."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_requests')
              field: client_request_id

      - name: current_quote_house_id
        description: "Identifiant de la venue associée au quote."
        tests:
          - not_null

      - name: current_quote_payment_type
        description: "Type de paiement du quote retenu normalisé en majuscules (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: current_quote_status
        description: "Statut du quote retenu normalisé en majuscules (ex : WON, LOST, PENDING)."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: current_quote_deposit_rate
        description: "Taux d'acompte du quote retenu normalisé en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: current_quote_start_at
        description: "Horodatage de début du séjour associé au quote."
        tests:
          - not_null

      - name: current_quote_end_at
        description: "Horodatage de fin du séjour associé au quote."
        tests:
          - not_null

      - name: current_quote_created_at
        description: "Horodatage de création du quote retenu."
        tests:
          - not_null

      - name: is_quote_role_consistent
        description: "Indique si le rôle du quote correspond au type de paiement du quote."
        tests:
          - not_null

      - name: is_request_consistent
        description: "Indique si client_request_id côté proposal et quote correspondent."
        tests:
          - not_null

      - name: is_house_consistent
        description: "Indique si house_id côté proposal et quote correspondent."
        tests:
          - not_null

      - name: is_billing_stage_known
        description: "Indique si le stage de facturation est reconnu dans dim_billing_stage."
        tests:
          - not_null

      - name: has_quote_data_quality_issue
        description: >
          Indique si une incohérence est détectée dans les données du quote
          (incohérence de request, house, payment type ou stage inconnu).
        tests:
          - not_null

int_current_quote_pricing_items.yml :

version: 2

models:
  - name: int_current_quote_pricing_items
    description: >
      Table intermédiaire retenant, pour chaque ligne tarifaire du quote courant d'une proposition,
      le snapshot tarifaire le plus avancé (INITIAL, FINAL, POST_FINAL).
      Le grain est : 1 ligne = 1 pricing_item rattaché au quote courant d'une proposition.

    tests:
      - dbt_utils.expression_is_true:
          expression: "client_proposal_status = upper(client_proposal_status)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_quote_role = upper(client_proposal_quote_role)"

      - dbt_utils.expression_is_true:
          expression: "billing_stage = upper(billing_stage)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_payment_type = upper(current_quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_status = upper(current_quote_status)"

      - dbt_utils.expression_is_true:
          expression: "quote_payment_type = upper(quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "quote_status = upper(quote_status)"

      - dbt_utils.expression_is_true:
          expression: "pricing_stage = upper(pricing_stage)"

      - dbt_utils.expression_is_true:
          expression: "pricing_type = upper(pricing_type)"

      - dbt_utils.expression_is_true:
          expression: "pricing_category = upper(pricing_category)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_start_at <= client_proposal_end_at"

      - dbt_utils.expression_is_true:
          expression: "current_quote_start_at <= current_quote_end_at"

      - dbt_utils.expression_is_true:
          expression: "quote_start_at <= quote_end_at"

      - dbt_utils.expression_is_true:
          expression: "total_price_base_price_price_with_vat >= total_price_base_price_price_without_vat"

      - dbt_utils.expression_is_true:
          expression: "is_billing_stage_known in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "is_pricing_stage_known in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_quote_data_quality_issue in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_current_quote_pricing_item_data_quality_issue in (true, false)"

    columns:
      - name: client_proposal_quote_pricing_item_key
        description: "Clé technique de la ligne tarifaire rattachée au quote et au snapshot tarifaire retenu."
        tests:
          - not_null
          - unique

      - name: quote_stage_key
        description: "Clé technique du quote courant retenu pour la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('dim_quote_stage')
              field: quote_stage_key

      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_proposals')
              field: client_proposal_id

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

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre de participants prévus dans la proposition."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: client_proposal_quote_role
        description: "Rôle du quote dans la proposition (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage
        description: "Stage de facturation du quote courant."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage_rank
        description: "Ordre logique du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: billing_stage_label
        description: "Libellé métier du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: ['Deposit', 'Balance', 'Post balance']

      - name: is_billing_stage_known
        description: "Indique si le stage de facturation est reconnu dans dim_billing_stage."
        tests:
          - not_null

      - name: client_proposal_quote_key
        description: "Clé technique du lien entre la proposition et le quote courant."
        tests:
          - not_null
          - relationships:
              to: ref('int_proposal_quotes')
              field: client_proposal_quote_key

      - name: current_quote_id
        description: "Identifiant du quote courant retenu pour la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: current_quote_client_request_id
        description: "Identifiant de la demande client côté quote courant."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_requests')
              field: client_request_id

      - name: current_quote_house_id
        description: "Identifiant de la venue associée au quote courant."
        tests:
          - not_null

      - name: current_quote_payment_type
        description: "Type de paiement du quote courant normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: current_quote_status
        description: "Statut du quote courant normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: current_quote_deposit_rate
        description: "Taux d'acompte du quote courant normalisé en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: current_quote_start_at
        description: "Horodatage de début du séjour associé au quote courant."
        tests:
          - not_null

      - name: current_quote_end_at
        description: "Horodatage de fin du séjour associé au quote courant."
        tests:
          - not_null

      - name: current_quote_created_at
        description: "Horodatage de création du quote courant."
        tests:
          - not_null

      - name: quote_id
        description: "Identifiant du quote auquel la ligne tarifaire est rattachée."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: quote_client_request_id
        description: "Identifiant de la demande client côté quote."
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
        description: "Type de paiement du quote normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: quote_status
        description: "Statut du quote normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: quote_deposit_rate
        description: "Taux d'acompte du quote normalisé en ratio décimal."
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

      - name: pricing_item_id
        description: "Identifiant unique de la ligne tarifaire."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_pricing_items')
              field: pricing_item_id

      - name: pricing_item_source_client_proposal_id
        description: "Valeur source de client_proposal_id portée par la ligne tarifaire, conservée à titre informatif."

      - name: service_owner_id
        description: "Identifiant du fournisseur ou du service owner."
        tests:
          - not_null

      - name: pricing_stage
        description: "Statut du snapshot tarifaire retenu pour la ligne tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: ['INITIAL', 'FINAL', 'POST_FINAL']

      - name: pricing_stage_rank
        description: "Ordre logique du snapshot tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: pricing_stage_label
        description: "Libellé métier du snapshot tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: ['Initial snapshot', 'Final snapshot', 'Post final snapshot']

      - name: pricing_type
        description: "Type métier de la ligne tarifaire normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['AD_HOC', 'USER_FEES', 'OWNER_FEES']

      - name: pricing_category
        description: "Catégorie métier de la ligne tarifaire normalisée en majuscules."
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
        description: "Taux de frais utilisateur converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_owner_fees_rate
        description: "Taux de commission propriétaire converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_discount_rate
        description: "Taux de remise converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: is_quote_role_consistent
        description: "Indique si le rôle du quote correspond au type de paiement du quote."
        tests:
          - not_null

      - name: is_request_consistent
        description: "Indique si client_request_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_house_consistent
        description: "Indique si house_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_source_client_proposal_id_consistent
        description: "Indique si le client_proposal_id porté par la ligne tarifaire est cohérent avec la proposition reconstruite via le quote, ou absent."
        tests:
          - not_null

      - name: has_quote_data_quality_issue
        description: "Indique si une incohérence est détectée dans les données du quote courant."
        tests:
          - not_null

      - name: is_pricing_stage_known
        description: "Indique si le snapshot tarifaire est reconnu dans dim_pricing_snapshot_stage."
        tests:
          - not_null

      - name: has_current_quote_pricing_item_data_quality_issue
        description: "Indique si une incohérence est détectée dans les données de la ligne tarifaire courante."
        tests:
          - not_null

int_pricing_item_revenue_components.yml :

version: 2

models:
  - name: int_pricing_item_revenue_components
    description: >
      Table intermédiaire enrichissant les lignes tarifaires du quote courant avec des composantes
      de revenu calculées à la ligne. Le grain est :
      1 ligne = 1 pricing_item du quote courant d'une proposition, enrichi avec des indicateurs
      de revenu, de GMV, de marge et de reversement partenaire.

    tests:
      - dbt_utils.expression_is_true:
          expression: "client_proposal_status = upper(client_proposal_status)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_quote_role = upper(client_proposal_quote_role)"

      - dbt_utils.expression_is_true:
          expression: "billing_stage = upper(billing_stage)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_payment_type = upper(current_quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "current_quote_status = upper(current_quote_status)"

      - dbt_utils.expression_is_true:
          expression: "quote_payment_type = upper(quote_payment_type)"

      - dbt_utils.expression_is_true:
          expression: "quote_status = upper(quote_status)"

      - dbt_utils.expression_is_true:
          expression: "pricing_stage = upper(pricing_stage)"

      - dbt_utils.expression_is_true:
          expression: "pricing_type = upper(pricing_type)"

      - dbt_utils.expression_is_true:
          expression: "pricing_category = upper(pricing_category)"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_start_at <= client_proposal_end_at"

      - dbt_utils.expression_is_true:
          expression: "current_quote_start_at <= current_quote_end_at"

      - dbt_utils.expression_is_true:
          expression: "quote_start_at <= quote_end_at"

      - dbt_utils.expression_is_true:
          expression: "total_price_base_price_price_with_vat >= total_price_base_price_price_without_vat"

      - dbt_utils.expression_is_true:
          expression: "is_billing_stage_known in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "is_pricing_stage_known in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "is_service_line in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "is_client_fee_line in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "is_partner_commission_line in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_quote_data_quality_issue in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_current_quote_pricing_item_data_quality_issue in (true, false)"

      - dbt_utils.expression_is_true:
          expression: "has_revenue_component_data_quality_issue in (true, false)"

    columns:
      - name: client_proposal_quote_pricing_item_key
        description: "Clé technique de la ligne tarifaire rattachée au quote et au snapshot tarifaire retenu."
        tests:
          - not_null
          - unique

      - name: quote_stage_key
        description: "Clé technique du quote courant retenu pour la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('dim_quote_stage')
              field: quote_stage_key

      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_proposals')
              field: client_proposal_id

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

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre de participants prévus dans la proposition."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: client_proposal_quote_role
        description: "Rôle du quote dans la proposition (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage
        description: "Stage de facturation du quote courant."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage_rank
        description: "Ordre logique du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: billing_stage_label
        description: "Libellé métier du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: ['Deposit', 'Balance', 'Post balance']

      - name: is_billing_stage_known
        description: "Indique si le stage de facturation est reconnu dans dim_billing_stage."
        tests:
          - not_null

      - name: client_proposal_quote_key
        description: "Clé technique du lien entre la proposition et le quote courant."
        tests:
          - not_null
          - relationships:
              to: ref('int_proposal_quotes')
              field: client_proposal_quote_key

      - name: current_quote_id
        description: "Identifiant du quote courant retenu pour la proposition."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: current_quote_client_request_id
        description: "Identifiant de la demande client côté quote courant."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_requests')
              field: client_request_id

      - name: current_quote_house_id
        description: "Identifiant de la venue associée au quote courant."
        tests:
          - not_null

      - name: current_quote_payment_type
        description: "Type de paiement du quote courant normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: current_quote_status
        description: "Statut du quote courant normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: current_quote_deposit_rate
        description: "Taux d'acompte du quote courant normalisé en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: current_quote_start_at
        description: "Horodatage de début du séjour associé au quote courant."
        tests:
          - not_null

      - name: current_quote_end_at
        description: "Horodatage de fin du séjour associé au quote courant."
        tests:
          - not_null

      - name: current_quote_created_at
        description: "Horodatage de création du quote courant."
        tests:
          - not_null

      - name: quote_id
        description: "Identifiant du quote auquel la ligne tarifaire est rattachée."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: quote_client_request_id
        description: "Identifiant de la demande client côté quote."
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
        description: "Type de paiement du quote normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: quote_status
        description: "Statut du quote normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: quote_deposit_rate
        description: "Taux d'acompte du quote normalisé en ratio décimal."
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

      - name: pricing_item_id
        description: "Identifiant unique de la ligne tarifaire."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_pricing_items')
              field: pricing_item_id

      - name: pricing_item_source_client_proposal_id
        description: "Valeur source de client_proposal_id portée par la ligne tarifaire, conservée à titre informatif."

      - name: service_owner_id
        description: "Identifiant du fournisseur ou du service owner."
        tests:
          - not_null

      - name: pricing_stage
        description: "Statut du snapshot tarifaire retenu pour la ligne tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: ['INITIAL', 'FINAL', 'POST_FINAL']

      - name: pricing_stage_rank
        description: "Ordre logique du snapshot tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: pricing_stage_label
        description: "Libellé métier du snapshot tarifaire."
        tests:
          - not_null
          - accepted_values:
              values: ['Initial snapshot', 'Final snapshot', 'Post final snapshot']

      - name: pricing_type
        description: "Type métier de la ligne tarifaire normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['AD_HOC', 'USER_FEES', 'OWNER_FEES']

      - name: pricing_category
        description: "Catégorie métier de la ligne tarifaire normalisée en majuscules."
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
        description: "Taux de frais utilisateur converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_owner_fees_rate
        description: "Taux de commission propriétaire converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_discount_rate
        description: "Taux de remise converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: is_service_line
        description: "Indique si la ligne tarifaire correspond à une prestation de service (AD_HOC)."
        tests:
          - not_null

      - name: is_client_fee_line
        description: "Indique si la ligne tarifaire correspond à des frais client (USER_FEES)."
        tests:
          - not_null

      - name: is_partner_commission_line
        description: "Indique si la ligne tarifaire correspond à une commission partenaire (OWNER_FEES)."
        tests:
          - not_null

      - name: service_gross_amount
        description: "Montant TTC brut de prestation, calculé uniquement pour les lignes AD_HOC."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: discount_amount
        description: "Montant de remise appliqué sur la prestation, calculé uniquement pour les lignes AD_HOC."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: service_net_amount
        description: "Montant TTC net de prestation après remise, calculé uniquement pour les lignes AD_HOC."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: client_fee_amount
        description: "Montant TTC des frais client, calculé uniquement pour les lignes USER_FEES."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: partner_commission_amount
        description: "Montant TTC de la commission partenaire, calculé uniquement pour les lignes OWNER_FEES."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: total_margin_amount
        description: "Montant total de marge porté par les lignes de frais et de commission (USER_FEES et OWNER_FEES)."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: gmv_service_net_amount
        description: "GMV net de service après remise, calculé uniquement sur les lignes AD_HOC."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: gmv_with_client_fees_amount
        description: "GMV incluant le net de service après remise et les frais client."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: net_supplier_payout_amount
        description: "Montant net théorique revenant au fournisseur : net de service diminué des commissions partenaire."
        tests:
          - not_null

      - name: is_quote_role_consistent
        description: "Indique si le rôle du quote correspond au type de paiement du quote."
        tests:
          - not_null

      - name: is_request_consistent
        description: "Indique si client_request_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_house_consistent
        description: "Indique si house_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_source_client_proposal_id_consistent
        description: "Indique si le client_proposal_id porté par la ligne tarifaire est cohérent avec la proposition reconstruite via le quote, ou absent."
        tests:
          - not_null

      - name: has_quote_data_quality_issue
        description: "Indique si une incohérence est détectée dans les données du quote courant."
        tests:
          - not_null

      - name: is_pricing_stage_known
        description: "Indique si le snapshot tarifaire est reconnu dans dim_pricing_snapshot_stage."
        tests:
          - not_null

      - name: has_current_quote_pricing_item_data_quality_issue
        description: "Indique si une incohérence est détectée dans les données de la ligne tarifaire courante."
        tests:
          - not_null

      - name: has_revenue_component_data_quality_issue
        description: "Indique si une incohérence est détectée dans les composantes de revenu calculées ou dans leurs prérequis de qualité."
        tests:
          - not_null

int_proposal_quote_pricing_items.yml :

version: 2

models:
  - name: int_proposal_quote_pricing_items
    description: >
      Table intermédiaire reliant les propositions, les quotes et les lignes tarifaires.
      Chaque ligne tarifaire est rattachée à un quote lui-même rattaché à une proposition.
      Le grain est : 1 ligne = 1 pricing_item rattaché à 1 quote rattaché à 1 proposition,
      pour un statut de snapshot tarifaire donné.

    tests:
      - dbt_utils.expression_is_true:
          expression: "client_proposal_quote_role = upper(client_proposal_quote_role)"

      - dbt_utils.expression_is_true:
          expression: "billing_stage = upper(billing_stage)"

      - dbt_utils.expression_is_true:
          expression: "pricing_deposit_status = upper(pricing_deposit_status)"

      - dbt_utils.expression_is_true:
          expression: "pricing_type = upper(pricing_type)"

      - dbt_utils.expression_is_true:
          expression: "pricing_category = upper(pricing_category)"

      - dbt_utils.expression_is_true:
          expression: "total_price_base_price_price_with_vat >= total_price_base_price_price_without_vat"

      - dbt_utils.expression_is_true:
          expression: "client_proposal_start_at <= client_proposal_end_at"

      - dbt_utils.expression_is_true:
          expression: "quote_start_at <= quote_end_at"

    columns:
      - name: client_proposal_quote_pricing_item_key
        description: "Clé technique générée à partir de (client_proposal_quote_key, pricing_item_id, pricing_deposit_status)."
        tests:
          - not_null
          - unique

      - name: client_proposal_quote_key
        description: "Clé technique du lien entre la proposition et le quote."
        tests:
          - not_null
          - relationships:
              to: ref('int_proposal_quotes')
              field: client_proposal_quote_key

      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_proposals')
              field: client_proposal_id

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

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre de participants prévus dans la proposition."
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0

      - name: client_proposal_quote_role
        description: "Rôle du quote dans la proposition (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage
        description: "Stage de facturation dérivé du rôle du quote via dim_billing_stage."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage_rank
        description: "Ordre logique du stage de facturation utilisé pour ordonner les étapes de paiement."
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3]
              quote: false

      - name: billing_stage_label
        description: "Libellé métier du stage de facturation."
        tests:
          - not_null
          - accepted_values:
              values: ['Deposit', 'Balance', 'Post balance']

      - name: quote_id
        description: "Identifiant unique du quote."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: quote_client_request_id
        description: "Identifiant de la demande client côté quote."
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
        description: "Type de paiement du quote normalisé en majuscules (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: quote_status
        description: "Statut du quote normalisé en majuscules (ex : WON, LOST, PENDING)."
        tests:
          - not_null
          - accepted_values:
              values: ['WON', 'LOST', 'PENDING']

      - name: quote_deposit_rate
        description: "Taux d'acompte du quote normalisé en ratio décimal."
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

      - name: is_quote_role_consistent
        description: "Indique si le rôle du quote dans la proposition correspond au payment_type du quote."
        tests:
          - not_null

      - name: is_request_consistent
        description: "Indique si client_request_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_house_consistent
        description: "Indique si house_id côté proposition et quote correspondent."
        tests:
          - not_null

      - name: is_billing_stage_known
        description: "Indique si le stage de facturation est reconnu dans dim_billing_stage."
        tests:
          - not_null

      - name: pricing_item_id
        description: "Identifiant unique de la ligne tarifaire."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_pricing_items')
              field: pricing_item_id

      - name: pricing_item_source_client_proposal_id
        description: "Valeur source de client_proposal_id présente dans la ligne tarifaire, conservée à titre informatif."
      - name: service_owner_id
        description: "Identifiant du fournisseur ou du service owner."
        tests:
          - not_null

      - name: pricing_deposit_status
        description: "Statut de snapshot tarifaire de la ligne tarifaire, normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['INITIAL', 'FINAL', 'POST_FINAL']

      - name: pricing_type
        description: "Type métier de la ligne tarifaire normalisé en majuscules."
        tests:
          - not_null
          - accepted_values:
              values: ['AD_HOC', 'USER_FEES', 'OWNER_FEES']

      - name: pricing_category
        description: "Catégorie métier de la ligne tarifaire normalisée en majuscules."
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
        description: "Taux de frais utilisateur converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_owner_fees_rate
        description: "Taux de commission propriétaire converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: price_option_discount_rate
        description: "Taux de remise converti en ratio décimal."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 1

      - name: is_source_client_proposal_id_consistent
        description: >
          Indique si le client_proposal_id porté par la ligne tarifaire est cohérent
          avec la proposition reconstruite via le quote, ou absent.
        tests:
          - not_null

int_proposal_quotes.yml :

version: 2

models:
  - name: int_proposal_quotes
    description: >
      Table intermédiaire reconstruisant la relation entre les propositions et les quotes.
      Une proposition peut référencer plusieurs devis correspondant aux différentes étapes
      du cycle de paiement (DEPOSIT, BALANCE, POST_BALANCE).

      Le grain est : 1 ligne = 1 quote associé à une proposition pour un rôle donné.

    tests:
      - dbt_utils.expression_is_true:
          expression: "client_proposal_quote_role = upper(client_proposal_quote_role)"

      - dbt_utils.expression_is_true:
          expression: "billing_stage = upper(billing_stage)"

    columns:

      - name: client_proposal_quote_key
        description: "Clé technique générée à partir de (client_proposal_id, client_proposal_quote_role, quote_id)."
        tests:
          - not_null
          - unique

      - name: client_proposal_id
        description: "Identifiant unique de la proposition commerciale."
        tests:
          - not_null
          - relationships:
              to: ref('stg_client_proposals')
              field: client_proposal_id

      - name: client_request_id
        description: "Identifiant de la demande client associée à la proposition."
        tests:
          - not_null

      - name: client_proposal_house_id
        description: "Identifiant de la venue proposée."
        tests:
          - not_null

      - name: client_proposal_status
        description: "Statut de la proposition normalisé en majuscules."

      - name: client_proposal_start_at
        description: "Horodatage de début du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_end_at
        description: "Horodatage de fin du séjour proposé."
        tests:
          - not_null

      - name: client_proposal_participants_count
        description: "Nombre de participants prévus dans la proposition."
        tests:
          - dbt_utils.accepted_range:
              min_value: 0

      - name: client_proposal_quote_role
        description: "Rôle du quote dans la proposition (DEPOSIT, BALANCE, POST_BALANCE)."
        tests:
          - not_null
          - accepted_values:
              values: ['DEPOSIT', 'BALANCE', 'POST_BALANCE']

      - name: billing_stage
        description: "Stage de facturation dérivé du rôle du quote via dim_billing_stage."

      - name: billing_stage_rank
        description: "Ordre logique du stage de facturation utilisé pour ordonner les étapes de paiement."

      - name: billing_stage_label
        description: "Libellé métier du stage de facturation."

      - name: quote_id
        description: "Identifiant unique du quote."
        tests:
          - not_null
          - relationships:
              to: ref('stg_quotes')
              field: quote_id

      - name: quote_client_request_id
        description: "Identifiant de la demande client côté quote."

      - name: quote_house_id
        description: "Identifiant de la venue associée au quote."

      - name: quote_payment_type
        description: "Type de paiement du quote normalisé en majuscules (DEPOSIT, BALANCE, POST_BALANCE)."

      - name: quote_status
        description: "Statut du quote normalisé en majuscules (ex : WON, LOST, PENDING)."

      - name: quote_deposit_rate
        description: "Taux d'acompte du quote normalisé en ratio décimal."

      - name: quote_start_at
        description: "Horodatage de début du séjour associé au quote."

      - name: quote_end_at
        description: "Horodatage de fin du séjour associé au quote."

      - name: quote_created_at
        description: "Horodatage de création du quote."
        tests:
          - not_null

      - name: is_quote_role_consistent
        description: "Indique si le rôle du quote dans la proposition correspond au payment_type du quote."

      - name: is_request_consistent
        description: "Indique si client_request_id côté proposition et quote correspondent."

      - name: is_house_consistent
        description: "Indique si house_id côté proposition et quote correspondent."

      - name: is_billing_stage_known
        description: "Indique si le stage de facturation est reconnu dans dim_billing_stage."

