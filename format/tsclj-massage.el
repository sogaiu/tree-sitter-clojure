;; tsclj-massage.el

;;; Code:

;; don't use tabs for indentation
(setq-default indent-tabs-mode nil)

(require 'js)

(setq js-indent-level 2)

(setq js-indent-align-list-continuation t)

(setq make-backup-files nil)

(defun tsclj-massage-and-save ()
  "Untabify, indent, and save buffer content."
  (let ((start (point-min))
        (end (point-max)))
    (message "Untabbifying...")
    (untabify start end)
    (indent-region start end nil)
    (save-buffer)
    (message "Saving...")))

(provide 'tsclj-massage)
;;; tsclj-massage.el ends here
