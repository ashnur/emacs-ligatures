;; -*- lexical-binding: t; -*-

;;; Lig-mode

(add-to-list 'auto-mode-alist '("\\.lig\\'" . lig-mode))

(define-derived-mode lig-mode fundamental-mode "Lig"
  (setq-local indent-line-function 'lisp-indent-line)
  (setq-local syntax-propertize-function 'lig-syntax-propertize-function))

(defun lig--match-lig (limit)
  (re-search-forward (rx word-start "hello" word-end) limit t))

(defun lig-mod-hook (overlay post-mod? start end &optional _)
  (when post-mod?
    (overlay-put overlay 'display nil)
    (overlay-put overlay 'modification-hooks nil)
    (set lig-overlay nil)))

(setq lig-overlay nil)

(defun lig-syntax-propertize-function (start-limit end-limit)
  (save-excursion
    (goto-char (point-min))

    (while (lig--match-lig end-limit)
      (let ((start (match-beginning 0))
            (end (match-end 0)))

        (unless (-contains? (overlays-at start) lig-overlay)
          (setq lig-overlay (make-overlay start end))
          (overlay-put lig-overlay 'display "")
          (overlay-put lig-overlay 'modification-hooks '(lig-mod-hook)))

        (setq num-lines 1)
        (save-excursion
          (while (> (lig-diff-in-indent start end num-lines) 0)
            (forward-line num-lines)
            (put-text-property (point) (+ 3 (point)) 'invisible t)
            ;; (compose-region (point) (+ 4 (point)) ?\s)

            (setq num-lines (1+ num-lines))
          ))))))

;; what if I maintained two separate buffers
;; one with the composed indentation and the other with the true indentation
;; the true buffer uses this overlay display trick
;; the fake buffer uses compose region instead
;; and we keep track of the indentation differences at each line
;; and then use the spacing trick on all lines with different indentation

;; "indirect buffers can have different major modes, overlays, markers"

;; Create a blank mode that only takes indentation from parent mode
;; create indirect buffer and set to this blank mode
;; since it is an indirect buffer, they share text naturally

;; since I cant make a separate overlay for compose
;; I could instead make an invisible overlay mirroring the lig-overlay

;; note can use evaporate property to nil the overlay automatically

;; note look at after-string and before-string properties for overlay
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Overlay-Properties.html#Overlay-Properties


(provide 'lig-mode)

(defun lig-diff-in-indent (start end num-lines)
  (compose-region start end "")

  (save-excursion
    (dotimes (i num-lines)
      (forward-line)
      (funcall (symbol-value 'indent-line-function))
      (setq composed-indent (current-indentation))))

  (decompose-region start end)

  (save-excursion
    (dotimes (i num-lines)
      (forward-line)
      (funcall (symbol-value 'indent-line-function))
      (setq uncomposed-indent (current-indentation))))

  (- uncomposed-indent composed-indent))


;;; Scratch

;; `text-property-any'
;; `text-properties-at'
;; '(?\s (Br . Bl) ?\s)
;; '(?\s (Br . Bl) ?\s (Br . Bl) ?\s)
;; (prettify-utils-generate (" " "  "))
