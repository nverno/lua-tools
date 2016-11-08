(require 'lua-tools)
(require 'ert)

(defmacro lua--should(from to)
  `(with-temp-buffer
     (let ()
       (insert ,from)
       (should (string= (buffer-substring-no-properties (point-min) (point-max))
                      ,to)))))

(defun lua--run-tests ()
  (interactive)
  (if (featurep 'ert)
      (ert-run-tests-interactively "lua--test")
    (message "cant run without ert.")))

(provide 'lua-tests)
