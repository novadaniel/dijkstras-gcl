(defrecord GCConst  [val])
(defrecord GCVar    [name])
(defrecord GCOp     [expr1 expr2 sym])

(defrecord GCComp   [expr1 expr2 sym])
(defrecord GCAnd    [test1 test2])
(defrecord GCOr     [test1 test2])
(defrecord GCTrue   [])
(defrecord GCFalse  [])

(defrecord GCSkip     [])
(defrecord GCAssign   [sym expr])
(defrecord GCCompose  [stmt1 stmt2])
(defrecord GCIf       [pairs])
(defrecord GCDo       [pairs])

(defrecord Config [stmt sig])

(def emptyState (fn [_] (0)))
(defn updateState [memory x n] (fn [i] (if (= x i) n (memory i))))

(defn reduce [config]
  (condp = (class (.stmt config))
    (class (GCConst. 0)) (:val (.stmt config))

    (class (GCVar. 0)) ((.sig config) (:name (.stmt config)))

    (class (GCOp. 0 0 0)) (case (:sym (.stmt config))
                            :plus (+ (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            :minus (- (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            :times (* (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            :div (/ (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            )

    (class (GCComp. 0 0 0)) (case (:sym (.stmt config))
                            :eq (= (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            :greater (> (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            :less (< (reduce (Config. (:expr1 (.stmt config)) (.sig config))) (reduce (Config. (:expr2 (.stmt config)) (.sig config))))
                            )

    (class (GCAnd. 0 0)) (and (reduce (Config. (:test1 (.stmt config)) (.sig config))) (reduce (Config. (:test2 (.stmt config)) (.sig config))))

    (class (GCOr. 0 0)) (or (reduce (Config. (:test1 (.stmt config)) (.sig config))) (reduce (Config. (:test2 (.stmt config)) (.sig config))))

    (class (GCTrue.)) true

    (class (GCFalse.)) false

    (class (GCSkip.)) config

    (class (GCAssign. 0 0)) (Config. (GCSkip.)
                                    (updateState (.sig config)
                                                 (:sym (.stmt config))
                                                 (reduce (Config. (:expr (.stmt config)) (.sig config)))))

    (class (GCCompose. 0 0)) (Config. (:stmt2 (.stmt config)) (.sig (reduce (Config. (:stmt1 (.stmt config)) (.sig config)))))

    (class (GCIf. 0)) (Config. (if (get (get (:pairs (.stmt config)) 0) 0)
                                 (get (get (:pairs (.stmt config)) 0) 1)
                                 (GCIf. (shuffle (rest (:pairs (.stmt config))))))
                               (.sig config))

    (class (GCDo. 0)) (Config. (if (get (get (:pairs (.stmt config)) 0) 0)
                                 (GCCompose. (get (get (:pairs (.stmt config)) 0) 1) (.stmt config))
                                 (GCDo. (shuffle (rest (:pairs (.stmt config))))))
                               (.sig config))
    )
  )
