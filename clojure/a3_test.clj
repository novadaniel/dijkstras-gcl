(ns testing)
(use 'clojure.test)
(load-file "small-step.clj")

;; A function to compute a given expression a number of times,
;; creating a list of the results.
;; Used to test the non-determinacy of GC programs involvings ifs and dos.
(defn times [n f]
  "Repeatedly evaluate `f` `n` times and concatenate together the results."
  (concat
    (repeatedly n #(eval f))))



(deftest test-state-assign-constant-one
  (is (= 1        ((.sig  (reduce (Config. (GCAssign. :x (GCConst. 1)) emptyState))) :x))))

(deftest test-stmt-assign-constant-one
  (is (= (GCSkip.) (.stmt (reduce (Config. (GCAssign. :x (GCConst. 1)) emptyState))))))

(deftest test-two-possible-branches-first
  (let [branch (GCIf. [[(GCTrue.) (GCAssign. :x (GCConst. 0))] [(GCTrue.) (GCAssign. :x (GCConst. 1))]])]
    (is (some #(= (GCAssign. :x (GCConst. 0)) %) (times 50 `(.stmt (reduce (Config. ~branch emptyState))))))))

(deftest test-two-possible-branches-second
  (let [branch (GCIf. [[(GCTrue.) (GCAssign. :x (GCConst. 0))] [(GCTrue.) (GCAssign. :x (GCConst. 1))]])]
    (is (some #(= (GCAssign. :x (GCConst. 1)) %) (times 50 `(.stmt (reduce (Config. ~branch emptyState))))))))

;; If we define `test-ns-hook`, it is called when running `run-tests`,
;; instead of just calling all tests in the namespace.
;; This lets us control the order of the tests.
(deftest test-ns-hook
  (test-state-assign-constant-one)
  (test-stmt-assign-constant-one)
  (test-two-possible-branches-first))

(run-tests 'testing)
