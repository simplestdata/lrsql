(ns lrsql.admin.interceptors.lrs-management
  (:require [clojure.spec.alpha :as s]
            [clojure.data.csv   :as csv]
            [clojure.edn        :as edn]
            [clojure.java.io    :as io]
            [io.pedestal.interceptor :refer [interceptor]]
            [io.pedestal.interceptor.chain :as chain]
            [lrsql.admin.protocol :as adp]
            [lrsql.spec.admin     :as ads]
            [com.yetanalytics.lrs.pedestal.interceptor.xapi :as i-xapi]
            [com.yetanalytics.lrs-reactions.spec :as rs])
  (:import [javax.servlet ServletOutputStream]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actor Delete
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def validate-delete-actor-params
  (interceptor
   {:name ::validate-delete-actor-params
    :enter (fn validate-delete-params [ctx]
             (let [params (get-in ctx [:request :json-params])]
               (if-some [err (s/explain-data
                              ads/delete-actor-spec 
                               params)]
                 (assoc (chain/terminate ctx)
                        :response
                        {:status 400
                         :body {:error (format "Invalid parameters:\n%s"
                                               (-> err s/explain-out with-out-str))}})
                 (assoc ctx ::data params))))}))

(def delete-actor
  (interceptor
   {:name ::delete-actor
    :enter (fn delete-actor [ctx]
             (let [{lrs :com.yetanalytics/lrs
                    params ::data}
                   ctx]
               (adp/-delete-actor lrs params)
               (assoc ctx
                      :response {:status 200
                                 :body params})))}))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CSV Download
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def validate-property-paths
  (interceptor
   {:name ::validate-property-paths
    :enter
    (fn validate-property-paths [ctx]
      (let [property-paths (-> ctx
                               (get-in [:request
                                        :params
                                        :property-paths])
                               edn/read-string)]
        (if-some [e (s/explain-data (s/every ::rs/path) property-paths)]
          (assoc (chain/terminate ctx)
                 :response
                 {:status 400
                  :body {:error (format "Invalid property paths:\n%s"
                                        (-> e s/explain-out with-out-str))}})
          ;; Need to dissoc since lrs.pedestal.interceptor.xapi/params-interceptor
          ;; restricts allowed keys in the query param map.
          (-> ctx
              (update-in [:request :params] dissoc :property-paths)
              (update-in [:request :query-params] dissoc :property-paths)
              (assoc-in [:request :property-paths] property-paths)))))}))

(def validate-query-params
  (interceptor
   (i-xapi/params-interceptor :xapi.statements.GET.request/params)))

(def csv-response-header
  {"Content-Type"        "text/csv"
   "Content-Disposition" "attachment"})

(defn- stream-csv
  [csv-data-seq]
  (fn [^ServletOutputStream os]
    (with-open [writer (io/writer os)]
      (csv/write-csv writer csv-data-seq :newline :cr+lf))))

(def download-statement-csv
  (interceptor
   {:name ::download-statement-csv
    :enter
    (fn download-statement-csv [ctx]
      (let [{lrs :com.yetanalytics/lrs
             request :request}
            ctx
            {:keys [property-paths query-params]}
            request
            csv-data-seq (adp/-get-statements-csv lrs
                                                  property-paths
                                                  query-params)]
        (assoc ctx
               :response {:status  200
                          :headers csv-response-header
                          :body    (stream-csv csv-data-seq)})))}))
