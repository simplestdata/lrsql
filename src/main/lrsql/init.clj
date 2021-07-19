(ns lrsql.init
  "Initialize HugSql functions and state."
  (:require [hugsql.core :as hugsql]
            [hugsql.adapter.next-jdbc :as next-adapter]
            [lrsql.interface.protocol :as ip]
            [lrsql.interface.data :as i-data]
            [lrsql.input.admin :as admin-input]
            [lrsql.input.auth  :as auth-input]
            [lrsql.ops.command.admin :as admin-cmd]
            [lrsql.ops.command.auth :as auth-cmd]))

(defn init-hugsql-adapter!
  "Initialize HugSql to use the next-jdbc adapter."
  []
  (hugsql/set-adapter! (next-adapter/hugsql-adapter-next-jdbc)))

(defn init-settable-params!
  "Set conversion functions for DB reading and writing depending on `db-type`."
  [db-type]
  (cond
    ;; H2
    (#{"h2" "h2:mem"} db-type)
    (do (i-data/set-h2-read!)
        (i-data/set-h2-write!))))

(defn init-ddl!
  "Execute SQL commands to create tables if they do not exist."
  [interface tx]
  (ip/-create-all! interface tx))

(defn insert-default-creds!
  "Seed the credential table with the default API key and secret, which are
   set by the environmental variables. The scope of the default credentials
   would be hardcoded as \"all\". Does not seed the table when the username
   or password is nil."
  [interface tx ?username ?password]
  (when (and ?username ?password)
    ;; TODO: Default admin also from config vars?
    (let [admin-in (admin-input/insert-admin-input
                    ?username
                    ?password)
          key-pair {:api-key    ?username
                    :secret-key ?password}
          cred-in  (auth-input/insert-credential-input
                    (:primary-key admin-in)
                    key-pair)
          scope-in (auth-input/insert-credential-scopes-input
                    key-pair
                    #{"all"})]
      (admin-cmd/insert-admin! interface tx admin-in)
      (auth-cmd/insert-credential! interface tx cred-in)
      (auth-cmd/insert-credential-scopes! interface tx scope-in))))
