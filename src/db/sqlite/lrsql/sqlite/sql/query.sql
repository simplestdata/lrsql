/* Authority subquery fragments */
-- See: https://stackoverflow.com/a/70099691 and https://stackoverflow.com/a/10410317

-- :frag sqlite-auth-subquery
(
  SELECT COUNT(DISTINCT stmt_auth.actor_ifi) = :authority-ifi-count
     AND COUNT(stmt_auth.actor_ifi) = COUNT(IIF(stmt_auth.actor_ifi IN (:v*:authority-ifis), 1, NULL))
  FROM statement_to_actor stmt_auth
  WHERE stmt_auth.statement_id = stmt.statement_id
    AND stmt_auth.usage = 'Authority'
)

-- :frag sqlite-auth-ref-subquery
(
  SELECT COUNT(DISTINCT stmt_auth.actor_ifi) = :authority-ifi-count
     AND COUNT(stmt_auth.actor_ifi) = COUNT(IIF(stmt_auth.actor_ifi IN (:v*:authority-ifis), 1, NULL))
  FROM statement_to_actor stmt_auth
  WHERE stmt_auth.statement_id = stmt_d.statement_id -- only difference is stmt_d instead of stmt
    AND stmt_auth.usage = 'Authority'
    AND stmt_auth.actor_ifi IN (:v*:authority-ifis)
)

/* Single-statement query */

-- :name query-statement
-- :command :query
-- :result :one
-- :doc Query for one statement using statement IDs.
SELECT stmt.payload
FROM xapi_statement stmt
WHERE statement_id = :statement-id
--~ (when (some? (:voided? params)) "AND is_voided = :voided?")
--~ (when (:authority-ifis params)  "AND :frag:sqlite-auth-subquery")

-- :name query-statement-exists
-- :command :query
-- :result :one
-- :doc Check for the existence of a Statement with `:statement-id`. Returns nil iff not found. Includes voided Statements.
SELECT 1
FROM xapi_statement
WHERE statement_id = :statement-id

/* Multi-statement query */

-- :frag sqlite-actors-join
LEFT JOIN statement_to_actor stmt_actor ON stmt.statement_id = stmt_actor.statement_id
LEFT JOIN statement_to_actor stmt_d_actor ON stmt_d.statement_id = stmt_d_actor.statement_id

-- :frag sqlite-activities-join
LEFT JOIN statement_to_activity stmt_activ ON stmt.statement_id = stmt_activ.statement_id
LEFT JOIN statement_to_activity stmt_d_activ ON stmt_d.statement_id = stmt_d_activ.statement_id

-- :name query-statements
-- :command :query
-- :result :many
-- :doc Query for one or more statements using statement resource parameters.
SELECT DISTINCT stmt.id, stmt.payload
FROM xapi_statement stmt
LEFT JOIN statement_to_statement sts on sts.ancestor_id = stmt.statement_id
LEFT JOIN xapi_statement stmt_d on sts.descendant_id = stmt_d.statement_id
--~ (when (:activity-iri params) ":frag:sqlite-activities-join")
--~ (when (:actor-ifi params)    ":frag:sqlite-actors-join")
WHERE stmt.is_voided = 0
/*~ (when (:from params)
     (if (:ascending? params) "AND stmt.id >= :from" "AND stmt.id <= :from"))  ~*/
--~ (when (:since params)     "AND stmt.id > :since")
--~ (when (:until params)     "AND stmt.id <= :until")
AND ((TRUE
--~ (when (:verb-iri params)       "AND stmt.verb_iri = :verb-iri")
--~ (when (:registration params)   "AND stmt.registration = :registration")
--~ (when (:actor-ifi params)      "AND stmt_actor.actor_ifi = :actor-ifi")
/*~ (when (and (:actor-ifi params) (not (:related-actors? params)))
                                   "AND stmt_actor.usage = 'Actor'") ~*/
--~ (when (:activity-iri params)   "AND stmt_activ.activity_iri = :activity-iri")
/*~ (when (and (:activity-iri params) (not (:related-activities? params)))
                                   "AND stmt_activ.usage = 'Object'") ~*/
--~ (when (:authority-ifis params) "AND :frag:sqlite-auth-subquery")
) OR (
TRUE
--~ (when (:verb-iri params)       "AND stmt_d.verb_iri = :verb-iri")
--~ (when (:registration params)   "AND stmt_d.registration = :registration")
--~ (when (:actor-ifi params)      "AND stmt_d_actor.actor_ifi = :actor-ifi")
/*~ (when (and (:actor-ifi params) (not (:related-actors? params)))
                                   "AND stmt_d_actor.usage = 'Actor'") ~*/
--~ (when (:activity-iri params)   "AND stmt_d_activ.activity_iri = :activity-iri")
/*~ (when (and (:activity-iri params) (not (:related-activities? params)))
                                   "AND stmt_d_activ.usage = 'Object'") ~*/
--~ (when (:authority-ifis params) "AND :frag:sqlite-auth-subquery")
--~ (when (:authority-ifis params) "AND :frag:sqlite-auth-ref-subquery")
))
--~ (if (:ascending? params) "ORDER BY stmt.id ASC" "ORDER BY stmt.id DESC")
--~ (when (:limit params)    "LIMIT :limit")

/* Statement Object Queries */

-- :name query-actor
-- :command :query
-- :result :one
-- :doc Query an actor with `:actor-ifi` and `:actor-type`.
SELECT payload FROM actor
WHERE actor_ifi = :actor-ifi
AND actor_type = :actor-type

-- :name query-activity
-- :command :query
-- :result :one
-- :doc Query an activity with `:activity-iri`.
SELECT payload FROM activity
WHERE activity_iri = :activity-iri

/* Statement Reference Queries */

-- :name query-statement-descendants
-- :command :query
-- :result :many
-- :doc Query for the descendants of a referencing `:ancestor-id`.
SELECT descendant_id FROM statement_to_statement
WHERE ancestor_id = :ancestor-id

/* Attachment Queries */

-- :name query-attachments
-- :command :query
-- :result :many
-- :doc Query for one or more attachments that references `:statement-id`.
SELECT attachment_sha, content_type, content_length, contents FROM attachment
WHERE statement_id = :statement-id

/* Document Queries */

-- :name query-state-document
-- :command :query
-- :result :one
-- :doc Query for a single state document using resource params. If `:registration` is missing then `registration` must be NULL.
SELECT contents, content_type, content_length, state_id, last_modified
FROM state_document
WHERE activity_iri = :activity-iri
AND agent_ifi = :agent-ifi
AND state_id = :state-id
--~ (if (:registration params) "AND registration = :registration" "AND registration ISNULL")

-- :name query-agent-profile-document
-- :command :query
-- :result :one
-- :doc Query for a single agent profile document using resource params.
SELECT contents, content_type, content_length, profile_id, last_modified
FROM agent_profile_document
WHERE agent_ifi = :agent-ifi
AND profile_id = :profile-id

-- :name query-activity-profile-document
-- :command :query
-- :result :one
-- :doc Query for a single activity profile document using resource params.
SELECT contents, content_type, content_length, profile_id, last_modified
FROM activity_profile_document
WHERE activity_iri = :activity-iri
AND profile_id = :profile-id

-- :name query-state-document-exists
-- :command :query
-- :result :one
-- :doc Query whether a particular state document exists. If `:registration` is missing then `registration` must be NULL.
SELECT 1 FROM state_document
WHERE activity_iri = :activity-iri
AND agent_ifi = :agent-ifi
AND state_id = :state-id
--~ (if (:registration params) "AND registration = :registration" "AND registration IS NULL")

-- :name query-agent-profile-document-exists
-- :command :query
-- :result :one
-- :doc Query whether a particular agent profile document exists.
SELECT 1 FROM agent_profile_document
WHERE agent_ifi = :agent-ifi
AND profile_id = :profile-id

-- :name query-activity-profile-document-exists
-- :command :query
-- :result :one
-- :doc Query whether a particular activity profile document exists.
SELECT 1 FROM activity_profile_document
WHERE activity_iri = :activity-iri
AND profile_id = :profile-id

-- :name query-state-document-ids
-- :command :query
-- :result :many
-- :doc Query for one or more state document IDs using resource params. If `:registration` is missing then `registration` must be NULL.
SELECT state_id FROM state_document
WHERE activity_iri = :activity-iri
AND agent_ifi = :agent-ifi
--~ (when (:registration params) "AND registration = :registration" "AND registration ISNULL")
--~ (when (:since params) "AND last_modified > :since")

-- :name query-agent-profile-document-ids
-- :command :query
-- :result :many
-- :doc Query for one or more agent profile document profile IDs using resource params.
SELECT profile_id FROM agent_profile_document
WHERE agent_ifi = :agent-ifi
--~ (when (:since params) "AND last_modified > :since")

-- :name query-activity-profile-document-ids
-- :command :query
-- :result :many
-- :doc Query for one or more activity profile document IDs using resource params.
SELECT profile_id FROM activity_profile_document
WHERE activity_iri = :activity-iri
--~ (when (:since params) "AND last_modified > :since")

/* Admin Accounts */

-- :name query-account
-- :command :query
-- :result :one
-- :doc Given an account `username` or `account-id`, return the ID and the hashed password, which can be used to verify the account.
SELECT id, passhash, username FROM admin_account
--~ (when (:username params)   "WHERE username = :username")
--~ (when (:account-id params) "WHERE id = :account-id")

-- :name query-account-oidc
-- :command :query
-- :result :one
-- :doc Given an account `username`, return the ID and OIDC issuer, which can be used to verify the OIDC identity.
SELECT id, oidc_issuer FROM admin_account
WHERE username = :username

-- :name query-account-by-id
-- :command :query
-- :result :one
-- :doc Given an account `account-id`, return the ID and OIDC issuer, if any.
SELECT id, oidc_issuer FROM admin_account
WHERE id = :account-id

-- :name query-all-accounts
-- :command :query
-- :result :many
-- :doc Return all admin accounts.
SELECT id, username FROM admin_account

-- :name query-account-exists
-- :command :query
-- :result :one
-- :doc Given an account `username` or `account-id`, return whether the account exists in the table.
SELECT 1 FROM admin_account
--~ (when (:username params)   "WHERE username = :username")
--~ (when (:account-id params) "WHERE id = :account-id")

-- :name query-account-count-local
-- :command :query
-- :result :one
-- :doc Count the local (non-OIDC) admin accounts present.
SELECT COUNT(id) local_account_count
FROM admin_account
WHERE oidc_issuer IS NULL

/* Credentials */

-- :name query-credentials
-- :command :query
-- :result :many
-- :doc Query all credentials associated with `:account-id`.
SELECT id, api_key, secret_key, label, is_seed FROM lrs_credential
WHERE account_id = :account-id

-- :name query-credential-ids
-- :command :query
-- :result :one
-- :doc Query the credential and account IDs associated with `:api-key` and `:secret-key`.
SELECT id AS cred_id, account_id FROM lrs_credential
WHERE api_key = :api-key
AND secret_key = :secret-key

-- :name query-credential-scopes
-- :command :query
-- :result :many
-- :doc Given an API key and a secret API key, return all authorized scopes (including NULL). Returns an empty coll if the credential is not present.
SELECT scope FROM credential_to_scope
WHERE api_key = :api-key
AND secret_key = :secret-key

/* LRS Status */

-- :name query-statement-count
-- :command :query
-- :result :one
-- :doc Return the number of statements in the LRS
SELECT COUNT(id) scount
FROM xapi_statement

-- :name query-actor-count
-- :command :query
-- :result :one
-- :doc Return the number of distinct statement actors
SELECT COUNT(DISTINCT actor_ifi) acount
FROM statement_to_actor
WHERE usage = 'Actor'

-- :name query-last-statement-stored
-- :command :query
-- :result :one
-- :doc Return the stored timestamp of the most recent statement
SELECT json_extract(payload, '$.stored') lstored
FROM xapi_statement
ORDER BY id DESC
LIMIT 1

-- :name query-platform-frequency
-- :command :query
-- :result :many
-- :doc Return counts of platforms used in statements.
SELECT COALESCE(json_extract(payload, '$.context.platform'), 'none') platform,
COUNT(id) scount
FROM xapi_statement
GROUP BY platform

-- :name query-timeline
-- :command :query
-- :result :many
-- :doc Return counts of statements by time unit for a given range.
SELECT substr(json_extract(payload, "$.stored"), 1, :unit-for) AS stored_time,
COUNT(id) scount
FROM xapi_statement
WHERE id > :since-id
  AND id <= :until-id
GROUP BY stored_time
ORDER BY stored_time ASC;

/* Statement Reactions */

-- :snip snip-json-extract
json_extract(:i:col, :v:path)

-- :snip snip-val
:v:val

-- :snip snip-col
:i:col

-- :snip snip-clause
:snip:left :sql:op :snip:right

-- :snip snip-and
--~ (str "(" (apply str (interpose " AND " (map-indexed (fn [idx _] (str ":snip:clauses." idx)) (:clauses params)))) ")")

-- :snip snip-or
--~ (str "(" (apply str (interpose " OR " (map-indexed (fn [idx _] (str ":snip:clauses." idx)) (:clauses params)))) ")")

-- :snip snip-not
(NOT :snip:clause)

-- :snip snip-contains
-- :doc Does the json at col and path contain the given value? A special case with differing structure across backends
(SELECT 1 FROM json_each(:i:col, :v:path) WHERE value = :snip:right)

-- :snip snip-query-reaction
SELECT :i*:select
FROM :i*:from
WHERE :snip:where;

-- :name query-reaction
:snip:sql

-- :name query-active-reactions
-- :command :query
-- :result :many
-- :doc Return all active `reaction` ids and rulesets
SELECT id, ruleset
FROM reaction
WHERE active IS TRUE;

-- :name query-all-reactions
-- :command :query
-- :result :many
-- :doc Query all active and inactive reactions
SELECT id, title, ruleset, active, created, modified, error
FROM reaction
WHERE active IS NOT NULL;

-- :name query-reaction-history
-- :command :query
-- :result :many
-- :doc For a given statement id, return all reactions (if any) leading to the issuance of that statement.
WITH RECURSIVE trigger_history (statement_id, reaction_id, trigger_id) AS (
  SELECT s.statement_id, s.reaction_id, s.trigger_id
  FROM xapi_statement s
  WHERE s.statement_id = :statement-id
  UNION ALL
  SELECT s.statement_id, s.reaction_id, s.trigger_id
  FROM xapi_statement s
  JOIN trigger_history th ON th.trigger_id = s.statement_id
)
SELECT reaction_id
FROM trigger_history
WHERE reaction_id IS NOT NULL;

/* JWT Blocklist */

-- :name query-blocked-jwt-exists
-- :command :query
-- :result :one
-- :doc Query that `:jwt` is in the blocklist. Excludes JWTs where `one_time_id` is not null.
SELECT 1 FROM blocked_jwt
WHERE jwt = :jwt
AND one_time_id IS NULL;

-- :name query-one-time-jwt-exists
-- :command :query
-- :result :one
-- :doc Query that `:jwt` with `:one-time-id` exists.
SELECT 1 FROM blocked_jwt
WHERE jwt = :jwt
AND one_time_id = :one-time-id;
