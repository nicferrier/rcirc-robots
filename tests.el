;; tests for rcirc-robots

(ert-deftest rcirc-robot-add-function ()
  (let (rcirc-robots--list)
    (rcirc-robots-add-function
     :name "test"
     :version 1
     :regex ".*"
     :function 'identity)
    (should
     (equal
      '((:name "test"
         :version 1
         :regex ".*"
         :function identity))
      rcirc-robots--list))
    (should-not
     (rcirc-robots-add-function
      :name "test"
      :version 1
      :regex ".*"
      :function 'identity))
    (should
     (equal
      '((:name "test"
         :version 1
         :regex ".*"
         :function identity))
      rcirc-robots--list))))
