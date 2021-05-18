/* Statement Query */

-- :name query-statement
-- :command :query
-- :result :many
-- :doc Query a statement using statement resource parameters.
-- :require [clojure.string :as cstr]
SELECT payload FROM xapi_statement
/*~
(when (:agent-ifi params)
 (str "INNER JOIN statement_to_agent"
      "\nON xapi_statement.statement_id = statement_to_agent.statement_id"
      "\nAND statement_to_agent.agent_ifi = :agent-ifi"
      (when-not (:related-agents? params)
       "\nAND statement_to_agent.usage = 'Actor'")))
~*/
/*~
(when (:activity-iri params)
 (str "INNER JOIN statement_to_activity"
      "\nON xapi_statement.statement_id = statement_to_activity.statement_id"
      "\nAND statement_to_activity.activity_iri = :activity-iri"
      (when-not (:related-activities? params)
       "\nAND statement_to_activity.usage = 'Object'")))
~*/
/*~
(some->>
 [(when (:statement-id params)
   "xapi_statement.statement_id = :statement-id")
  (when (some? (:voided? params))
   "xapi_statement.is_voided = :voided?")
  (when (:verb-iri params)
   "xapi_statement.verb_iri = :verb-iri")
  (when (:registration params)
   "xapi_statement.registration = :registration")
  (when (:since params)
   "xapi_statement.stored > :since")
  (when (:until params)
   "xapi_statement.stored <= :until")]
 (filter some?)
 not-empty
 (cstr/join "\nAND ")
 (str "WHERE\n"))
~*/
--~ (when (:ascending? params) "ORDER BY xapi_statement.stored")
--~ (when (:limit params) "LIMIT :limit")

/* Attachment Query */

-- :name query-attachments
-- :command :query
-- :result :many
-- :doc Query attachments using query parameters
SELECT attachment.attachment_sha, content_type, content_length, payload
FROM attachment
INNER JOIN statement_to_attachment
ON attachment.attachment_sha = statement_to_attachment.attachment_sha
AND statement_to_attachment.statement_id = :statement-id
-- WHERE :attachments? = TRUE

/* Existence Checks */

-- :name query-agent-exists
-- :command :query
-- :result :one
-- :doc Check for the existence of an Agent with a given IFI in the agent table. Returns nil iff not found.
SELECT 1 FROM agent
WHERE agent_ifi = :agent-ifi

-- :name query-activity-exists
-- :command :query
-- :result :one
-- :doc Check for the existence of an Activity with a given IRI in the activity table. Returns nil iff not found.
SELECT 1 FROM activity
WHERE activity_iri = :activity-iri

-- :name query-attachment-exists
-- :command :query
-- :result :one
-- :doc Check for the existence of an Attachment with a given SHA2 hash in the attachment table. Returns nil iff not found.
SELECT 1 FROM attachment
WHERE attachment_sha = :attachment-sha

/* Document Queries */

-- :name query-state-document
-- :command :query
-- :result :one
-- :doc Query for a single state document.
SELECT document, state_id, last_modified FROM state_document
WHERE activity_iri = :activity-iri
AND agent_ifi = :agent-ifi
AND state_id = :state-id
--~ (when (:?registration params) "AND registration = :?registration")

-- :name query-state-document-ids
-- :command :query
-- :result :many
-- :doc Query for state document IDs.
SELECT state_id FROM state_document
WHERE activity_iri = :activity-iri
AND agent_ifi = :agent-ifi
--~ (when (:?registration params) "AND registration = :?registration")
--~ (when (:since params) "AND last_modified > :since")

-- :name query-agent-profile-document
-- :command :query
-- :result :one
-- :doc Query for a single agent profile document.
SELECT document, profile_id, last_modified FROM agent_profile_document
WHERE agent_ifi = :agent-ifi
AND profile_id = :profile-id

-- :name query-agent-profile-document-ids
-- :command :query
-- :result :many
-- :doc Query for agent profile document profile IDs.
SELECT profile_id FROM agent_profile_document
WHERE agent_ifi = :agent-ifi
--~ (when (:since params) "AND last_modified > :since")

-- :name query-activity-profile-document
-- :command :query
-- :result :one
-- :doc Query for a single activity profile document.
SELECT document, profile_id, last_modified FROM activity_profile_document
WHERE activity_iri = :activity-iri
AND profile_id = :profile-id

-- :name query-activity-profile-document-ids
-- :command :query
-- :result :many
-- :doc Query for activity profile document IDs.
SELECT profile_id FROM activity_profile_document
WHERE activity_iri = :activity-iri
--~ (when (:since params) "AND last_modified > :since")
