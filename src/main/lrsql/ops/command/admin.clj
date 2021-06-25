(ns lrsql.ops.command.admin
  (:require [lrsql.functions :as f]))

(defn insert-admin!
  "Insert a new admin username, hashed password, and the hash salt into the
   `admin_account` table."
  [tx input]
  (if-not (f/query-account-exists tx (select-keys input [:username]))
    (do
      (f/insert-admin-account! tx input)
      (:primary-key input))
    :lrsql.admin/existing-account-error))

(defn delete-admin!
  "Delete the admin account and any associated credentials."
  [tx input]
  (f/delete-admin-credentials! tx input)
  (f/delete-admin-account! tx input))
