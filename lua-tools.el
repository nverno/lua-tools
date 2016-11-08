;;; lua-tools --- 

;; This is free and unencumbered software released into the public domain.

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/lua-tools
;; Package-Requires: 
;; Created:  8 November 2016

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; [![Build Status](https://travis-ci.org/nverno/lua-tools.svg?branch=master)](https://travis-ci.org/nverno/lua-tools)

;;; Code:
(eval-when-compile
  (require 'cl-lib)
  (defvar yas-snippet-dirs)
  (defvar company-backends)
  (defvar lua-process-buffer)
  (defvar lua-prompt-regexp)
  (defvar lua-traceback-line-re))
(require 'lua-mode nil t)

(defvar lua-tools--dir nil)
(when load-file-name
  (setq lua-tools--dir (file-name-directory load-file-name)))

;; ------------------------------------------------------------
;;; Inferior process

;; https://github.com/skeeto/.emacs.d/blob/master/etc/lua-extras.el

;; send buffer or restart with prefix
(defun lua-tools-inf-send-buffer (arg)
  (interactive "P")
  (if arg (lua-restart-with-whole-buffer)
    (lua-send-buffer)))

;; toggle lua process buffer
(defun lua-tools-inf-process-buffer ()
  (interactive)
  (or (and (get-buffer-window lua-process-buffer)
           (lua-hide-process-buffer))
      (lua-show-process-buffer)))

;; pop lua error message in `special-mode'
(defun lua-tools-inf-error (message)
  (with-current-buffer (get-buffer-create "*lua-error*")
    (special-mode)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert message))
    (pop-to-buffer (current-buffer))))

;; echo comint result in minibuffer
(defun lua-tools-inf-echo (result)
  (with-temp-buffer
    (insert result)
    (re-search-backward lua-prompt-regexp nil :noerror)
    (let* ((fixed (buffer-substring (point-min) (point)))
           (trim "^[[:space:]]+\\|[[:space:]]+$")
           (actual (replace-regexp-in-string trim "" fixed)))
      (if (string-match-p lua-traceback-line-re actual)
          (lua-tools-inf-echo actual)
        (message "%s" actual)))))

(defun lua-tools-inf-add-filter ()
  (with-current-buffer lua-process-buffer
    (make-local-variable 'company-backends)
    (cl-pushnew 'company-lua company-backends)
    (add-hook 'comint-output-filter-functions 'lua-tools-inf-echo
              nil 'local)))

(add-function :after (symbol-function 'lua-start-process)
              'lua-tools-inf-add-filter)
;;; Imenu

(defvar lua-tools-imenu
  '(("Variable" "^ *\\([a-zA-Z0-9_.]+\\) *= *{ *[^ ]*$" 1)
    ("Function" "function +\\([^ (]+\\).*$" 1)
    ("Module" "^ *module +\\([^ ]+\\) *$" 1)
    ("Variable" "^ *local +\\([^ ]+\\).*$" 1)))

;; ------------------------------------------------------------
;;; Setup

(eval-after-load 'yasnippet
  '(let ((dir (expand-file-name "snippets" lua-tools--dir))
         (dirs (or (and (consp yas-snippet-dirs) yas-snippet-dirs)
                   (cons yas-snippet-dirs ()))))
     (unless (member dir dirs)
       (setq yas-snippet-dirs (delq nil (cons dir dirs))))
     (yas-load-directory dir)))

;; ------------------------------------------------------------

(declare-function lua-restart-with-whole-file "lua-mode")
(declare-function lua-restart-with-whole-buffer "lua-mode")
(declare-function lua-send-buffer "lua-mode")
(declare-function lua-hide-process-buffer "lua-mode")
(declare-function lua-show-process-buffer "lua-mode")

(provide 'lua-tools)
;;; lua-tools.el ends here
