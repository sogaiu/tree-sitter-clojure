;;; classify-parse-errors --- classify tree-sitter parse errors

;;; Commentary:

;; issues:
;;
;; * File path computation by `cpe-open-current-file' is on the
;;   hard-wired side.

;; consider tweaking split-width-threshold like:
;;
;;   (setq split-width-threshold 1000)
;;
;; so that when viewing the output of a session in a frame, its width
;; can be made large and yet C-o display the related file in a buffer
;; underneath instead of to the side.

;;; Code:

(require 'dired-x)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cpe-proj-root
  ;; XXX: is this good enough?
  (file-name-directory (or load-file-name (buffer-file-name))))

(defvar cpe-data-dir-name
  "data")

(defvar cpe-data-dir-path
  (concat cpe-proj-root cpe-data-dir-name))

(defvar cpe-file-path
  (concat cpe-data-dir-path "/classify-parse-errors.tsv"))

(defvar cpe-error-files-default-name
  "clojars-error-files.txt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cpe-new-session (path)
  "Start a new session.

Optional argument PATH specifies a path to a file with paths in it."
  (interactive
   (list (read-file-name "Errors file name: "
                         (concat cpe-data-dir-name "/")
                         nil
                         t
                         cpe-error-files-default-name)))
  (find-file path)
  (shell-command-on-region (point-min) (point-max)
                           "xargs ls -al")
  (switch-to-buffer "*Shell Command Output*")
  ;; XXX: because atm all of the file paths are absolute
  (dired-virtual "/"))

(defun cpe-append-entry (reason)
  "Append a new entry with REASON."
  ;; XXX: read in past reasons from cpe-file-path?
  ;; XXX: should prune tab characters from reason
  (interactive "sReason: ")
  (when-let* ((file-name (dired-get-filename))
              (checksum (md5 (find-file-noselect file-name)))
              (parent-path (file-truename (concat cpe-data-dir-path "/")))
              (short-path (substring (file-truename file-name)
                                     (length parent-path))))
      ;; XXX
    (message "reason: %s" reason)
    (message "file name: %s" file-name)
    (message "checksum: %s" checksum)
    (message "parent-path: %s" parent-path)
    (message "short-path: %s" short-path)
    (append-to-file (concat checksum "\t"
                            reason "\t"
                            short-path "\n")
                    nil cpe-file-path)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cpe--parse-current-row ()
  "Parse current row."
  (save-excursion
    (let ((start nil) (end nil))
      (beginning-of-line)
      (setq start (point))
      (end-of-line)
      (setq end (point))
      (string-split (buffer-substring-no-properties start end) "\t"))))

(defun cpe--first-number-from-location (location)
  "Extract first number from LOCATION."
  (string-match "^\\([0-9]+\\)" location)
  (match-string 0 location))

;; XXX: full path construction may be problematic
(defun cpe-open-row-file ()
  "Visit file for current row."
  (interactive)
  (when-let* ((row (cpe--parse-current-row))
              (path (nth 2 row))
              (location (or (nth 3 row) "1"))
              (first-line (cpe--first-number-from-location location))
              (file-path (concat cpe-data-dir-path
                                 "/../clojars-samples/data/clojars-repos/"
                                 path)))
    (find-file file-path)
    (forward-line (1- (string-to-number first-line)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'classify-parse-errors)
;;; classify-parse-errors.el ends here
