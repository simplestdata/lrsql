(ns lrsql.ops.command.auth
  (:require [lrsql.functions :as f]))

;; Insertion
  ;; TODO: Dupe checking

(defn insert-credential!
  [tx input]
  (f/insert-credential! tx input))

(defn insert-credential-scopes!
  "Insert a seq of credential inputs, each which may have a different scope
   (but should have the same API keys)."
  [tx inputs]
  (doall (map (partial f/insert-credential-scope! tx) inputs)))

;; Deletion
;; TODO: Existence checking

(defn delete-credential-scopes!
  [tx inputs]
  (doall (map (partial f/delete-credential-scope! tx) inputs)))

(defn delete-credential!
  [tx input]
  (f/delete-credential! tx input))
