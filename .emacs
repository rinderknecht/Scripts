;; -*- emacs-lisp -*-

;; Configuration file for Emacs

;; -------------------------------------------------------------------
;; Useful Tips
;;
;; Ctrl-x Ctrl-+ Enlarge font
;; Ctrl-x Ctrl-- Shrink font
;;
;; Reloading this file:
;; M-x load-file
;; and hit return twice.
;;
;; Inserting one TAB: C-q TAB
;;
;; Input method: C-u C-\ <input method name>
;; e.g. C-u C-\ korean-hangul
;;      C-u C-\ french-prefix
;;      C-u C-\ swedish-postfix
;;
;; Resuming spell checking: C-u M-$
;;
;; Moving to the character position <n> on the current line:
;; M-g <TAB> <n>
;;
;; To toggle between case-sensitive and case-insensitive search, use
;; M-x toggle-case-fold-search
;;
;; To rename all occurrences of the identifier at the focus point
;; M-x merlin-iedit-occurrences
;;
;; Key translations Starting With C-x:
;; C-x 8 ?       ¿
;; C-x 8 !         ¡
;; C-x 8 <         «
;; C-x 8 >         »
;;  -------------------------------------------------------------------
;; Package management

(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(unless (require 'use-package nil 'noerror)
 (package-refresh-contents)
 (package-install 'use-package))

;; -------------------------------------------------------------------
;; Bindings, fonts, TABs, end of files and X windows

;; Navigating buffers with the arrow keys
;;
(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <right>") 'windmove-right)
(global-set-key (kbd "C-x <left>") 'windmove-left)

;; Different default fonts depending on the machine
;;
;; (if (string-equal system-name "haechi")
;;     (set-default-font "Monospace-14")
;;     (if (string-equal system-name "dorongnyong.local")
;;         (set-default-font "Monospace-14")))

(defun set_small_font () (interactive)
       (custom-set-faces '(default ((t (:inherit nil :stipple
        nil :background "black" :foreground "wheat" :inverse-video
        nil :box nil :strike-through nil :overline nil :underline
        nil :slant normal :weight normal :height 142 :width
        normal :foundry "PfEd" :family "DejaVu Sans Mono"))))))

(global-set-key (kbd "C-s-f") 'set_small_font)

(defun set_large_font () (interactive)
       (custom-set-faces '(default ((t (:inherit nil :stipple
        nil :background "black" :foreground "wheat" :inverse-video
        nil :box nil :strike-through nil :overline nil :underline
        nil :slant normal :weight normal :height 170 :width
        normal :foundry "PfEd" :family "DejaVu Sans Mono"))))))

(global-set-key (kbd "C-s-g") 'set_large_font)

;; Customisations
;;
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(case-fold-search nil)
 '(column-number-mode t)
 '(custom-enabled-themes '(wheatgrass))
 '(package-selected-packages
   '(iedit json-mode exec-path-from-shell deferred use-package))
 '(safe-local-variable-values '((ispell-dictionary . "british")))
 '(save-place-mode t nil (saveplace))
 '(text-mode-hook
   '(turn-on-auto-fill
     (lambda nil
       (set-input-method "french-prefix"))
     text-mode-hook-identify))
 '(tool-bar-mode nil)
 '(tuareg-font-lock-symbols t))

;; Main window geometry
;;
;; (if (string-equal system-name "haechi")
;;     (setq default-frame-alist '((height . 30)(width . 82)))
;;     (if (string-equal system-name "dorongnyong.local")
;;         (setq default-frame-alist '((height . 125)(width . 70)))))
(setq default-frame-alist '((height . 145)(width . 79)))
;;(setq default-frame-alist '((height . 35)(width . 79)))

;; Stop leaving backup~ files scattered everywhere
;;
(setq backup-directory-alist '(("." . "~/.emacs-backups")))

;; Bind M-x goto-line to C-x g
;;
(global-set-key "\C-xg" 'goto-line)

;; MacOS X specific stuff
;;
;; (setq mac-command-key-is-meta nil)

;; Remove graphic tool bar
;;
(tool-bar-mode -1)

;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the
;; right under X, instead of the default, backspace behavior.
;;
(global-set-key [delete] 'delete-char)
(global-set-key [kp-delete] 'delete-char)

;; Always end a file with a newline
;;
(setq require-final-newline nil)

;; Stop at the end of the file, not just add lines
;;
(setq next-line-add-newlines nil)

;; Show carriage return and end of file characters (MS DOS text files)
;;
(setq inhibit-eol-conversion nil)

;; Tabulations displayed as 2 blank characters by default
;;
(setq default-tab-width 2)

;; Show line-number in the mode line
;;
(line-number-mode 1)

;; Show column-number in the mode line
;;
(setq column-number-mode t)

;; By default, indent with spaces instead of TABs (\t)
;;
(setq-default indent-tabs-mode nil)

;; TAB width is 2 spaces
;;
(setq-default tab-width 2)

;; Show trailing whitespace
;;
(setq-default show-trailing-whitespace t)

;; Call M-x delete-trailing-whitespace before saving
;;
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Draw tabs with the same color as trailing whitespace
;;
(add-hook 'font-lock-mode-hook
  '(lambda () (font-lock-add-keywords
                 nil '(("\t" 0 'trailing-whitespace prepend)))))

;; Wrap long lines by word boundary
;;
(global-visual-line-mode 1) ;; 1 for on, 0 for off.

;; Electric buffer and no startup message
;;
(global-set-key "" 'electric-buffer-list)

(setq inhibit-startup-message t)

;; 8-bits display and input characters
;;
(add-hook 'text-mode-hook
  (lambda () (set-input-method "french-prefix")))

(add-hook 'latex-mode-hook
  (lambda () (set-input-method "french-prefix")))

;; UTF-8 encoding
;
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; -------------------------------------------------------------------
;; Spell checker in Emacs is `aspell'
;;
(if (string-equal system-name "haechi")
    (setq ispell-program-name "/usr/bin/aspell")
  (if (string-equal system-name "dorongnyong.local")
      (setq ispell-program-name "/opt/local/bin/aspell")))

(setq ispell-dictionary "british")

;; -------------------------------------------------------------------
;; GNU Makefile mode
;;
(setq auto-mode-alist
  (cons '("Makefile" . makefile-gmake-mode)
    (cons '("Makefile\.in" . makefile-gmake-mode)
auto-mode-alist)))

(add-hook 'makefile-gmake-mode-hook '(lambda ()
 (setq makefile-gmake-indent 2)))

;; -------------------------------------------------------------------
;; Java mode
;;
(global-font-lock-mode t)

(add-hook 'java-mode-hook (lambda () (setq c-basic-offset 2)))

(add-hook 'java-mode-hook (lambda () (setq c-basic-offset 2
                                      tab-width 2
                                      indent-tabs-mode nil)))

;; -------------------------------------------------------------------
;; Prolog mode (SWI-Prolog)
;;
;; (if (string-equal system-name "dorongnyong.local")
;;   (setq load-path (cons "/Applications/Aquamacs.app/Contents/Resources/lisp/aquamacs/edit-modes" load-path))
;;   (autoload 'run-prolog "prolog" "Start a Prolog sub-process." t)
;;   (autoload 'prolog-mode "prolog" "Major mode for editing Prolog programs." t))

;; (setq auto-mode-alist
;;   (append '(("\\.pl$" . prolog-mode)
;;             ("\\.P$"  . prolog-mode)) auto-mode-alist))

;; (setq prolog-program-name "pl")
;; (setq prolog-consult-string "[user].\n")
;; (setq prolog-indent-width 4)

;; -------------------------------------------------------------------
;; Promela mode
;;
;; (add-to-list 'load-path "~/.emacs_modes/promela")
;; (add-to-list 'auto-mode-alist '("\\.pml$" . promela-mode))
;; (autoload 'promela-mode "promela-mode" "Promela mode." t)

;; -------------------------------------------------------------------
;; ASN.1 & GDMO
;;
(add-to-list 'load-path "~/.emacs_modes/asn1")
(add-to-list 'auto-mode-alist '("\\.asn1$" . asn1-mode))
(add-to-list 'auto-mode-alist '("\\.asn$" . asn1-mode))
(add-to-list 'auto-mode-alist '("\\.gdmo$" . asn1-mode))
(autoload 'asn1-mode "asn1-mode" "ASN.1 mode." t)

;; -------------------------------------------------------------------
;; Markdown
;;
(add-to-list 'load-path "~/.emacs_modes/markdown")
(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
(autoload 'markdown-mode "markdown-mode" "Markdown mode." t)

;; -------------------------------------------------------------------
;; PascaLIGO
;;
(add-to-list 'auto-mode-alist '("\\.ligo$" . pascal-mode))
(add-to-list 'auto-mode-alist '("\\.pligo$" . pascal-mode))

;; -------------------------------------------------------------------
;; JsLIGO
;;
(add-to-list 'auto-mode-alist '("\\.jsligo$" . js-mode))

;; -------------------------------------------------------------------
;; Dune
;;
(add-to-list 'auto-mode-alist '("dune$" . lisp-mode))

;; -------------------------------------------------------------------
;; OCaml mode
;;
;; (add-to-list 'load-path "~/.emacs_modes/ocaml")
;; (add-to-list 'auto-mode-alist '("\\.ml[iylp]?$" . caml-mode))
;; (autoload 'caml-mode "caml" "OCaml mode." t)

;; (if window-system (require 'caml-font))

;; -------------------------------------------------------------------
;; Tuareg mode
;;
(add-to-list 'load-path "~/.emacs_modes/tuareg")
(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug "camldebug" "Run the Caml debugger" t)
;;(autoload 'tuareg-imenu-set-imenu "tuareg-imenu"
;;  "Configuration of imenu for tuareg" t)
;;(add-hook 'tuareg-mode-hook 'tuareg-imenu-set-imenu)
(setq auto-mode-alist
      (append '(("\\.ml[ily]?$" . tuareg-mode)
                ("\\.mligo$" . tuareg-mode)
                ("\\.topml$" . tuareg-mode))
              auto-mode-alist))
(require 'tuareg)
(setq tuareg-font-lock-symbols-alist
      `(("fun" . ,(decode-char 'ucs 955))
        ("sqrt" . ,(decode-char 'ucs 8730))
;;        ("not" . ,(decode-char 'ucs 172))
;;        ("or" . ,(decode-char 'ucs 8744)); 'LOGICAL OR' (U+2228)
        ("&&" . ,(decode-char 'ucs 8743)); 'LOGICAL AND' (U+2227)
        ("||" . ,(decode-char 'ucs 8744))
        ("[|" . ,(decode-char 'ucs 12314)) ;; 〚
        ("|]" . ,(decode-char 'ucs 12315)) ;; 〛
        ("*." . ,(decode-char 'ucs 215))
        ("/." . ,(decode-char 'ucs 247))
        ("->" . ,(decode-char 'ucs 8594))
        ("<-" . ,(decode-char 'ucs 8592))
        ("<=" . ,(decode-char 'ucs 8804))
        (">=" . ,(decode-char 'ucs 8805))
;;        ("<>" . ,(decode-char 'ucs 8800))
;;        ("==" . ,(decode-char 'ucs 8801))
        ("!=" . ,(decode-char 'ucs 8802))
        ("<=>" . ,(decode-char 'ucs 8660))
;;        (":=" . ,(decode-char 'ucs 8656))
        ("infinity" . ,(decode-char 'ucs 8734))
        ;; Some greek letters for type parameters.
        ("'a" . ,(decode-char 'ucs 945))
        ("'b" . ,(decode-char 'ucs 946))
        ("'c" . ,(decode-char 'ucs 947))
        ("'d" . ,(decode-char 'ucs 948))
        ;; ("'e" . ,(decode-char 'ucs 949))
        ;; ("'f" . ,(decode-char 'ucs 966))
        ;; ("'i" . ,(decode-char 'ucs 953))
        ;; ("'k" . ,(decode-char 'ucs 954))
        ;; ("'m" . ,(decode-char 'ucs 956))
        ;; ("'n" . ,(decode-char 'ucs 957))
        ;; ("'o" . ,(decode-char 'ucs 969))
        ;; ("'p" . ,(decode-char 'ucs 960))
        ;; ("'r" . ,(decode-char 'ucs 961))
        ;; ("'s" . ,(decode-char 'ucs 963))
        ;; ("'t" . ,(decode-char 'ucs 964))
        ;; ("'x" . ,(decode-char 'ucs 958))
        ;; Mine
        ("<@" . ?○)
        ("|>" . ?▷)
        ("@@" . ?⥁)
))

;; -------------------------------------------------------------------
;; OCP Ident

;;(add-to-list 'load-path "/home/rinderkn/.opam/default/share/emacs/site-lisp")
;;(require 'ocp-indent)

;; -------------------------------------------------------------------
;; Merlin
;;
(let ((opam-share (ignore-errors (car (process-lines "opam" "config" "var" "share")))))
 (when (and opam-share (file-directory-p opam-share))
  (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share))
  (autoload 'merlin-mode "merlin" nil t nil)
  (add-hook 'tuareg-mode-hook 'merlin-mode t)
  (add-hook 'caml-mode-hook 'merlin-mode t)))
(setq merlin-ac-setup 'easy)

;; -------------------------------------------------------------------
;; Email mode
;;
;; (add-to-list 'auto-mode-alist'("\\.eml" . text-mode))

;; -------------------------------------------------------------------
;; nXML mode for XSLT and XML
;;
(add-to-list 'load-path "~/.emacs_modes/xml")
(add-to-list 'auto-mode-alist
             '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\)\\'" . nxml-mode))

;; -------------------------------------------------------------------
;; Erlang mode
;;
(add-to-list 'load-path "~/.emacs_modes/erlang")
(add-to-list 'auto-mode-alist '("\\.erl$" . erlang-mode))
(autoload 'erlang-mode "erlang" "Erlang mode." t)

;; TABs are changed into spaces.
;;
(add-hook 'erlang-mode-hook '(lambda () (setq indent-tabs-mode nil)))

;; -------------------------------------------------------------------
;; Scala mode
;;
;; (add-to-list 'load-path "~/.emacs_modes/scala")
;; (require 'scala-mode-auto)

;; -------------------------------------------------------------------
;; Eiffel mode
;;
;;(add-to-list 'load-path "~/.emacs_modes/eiffel")
;;(add-to-list 'auto-mode-alist '("\\.e$" . eiffel-mode))
;;(autoload 'eiffel-mode "eiffel" "Eiffel mode." t)
;;(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
;; '(default ((t (:family "DejaVu Sans Mono" :foundry "PfEd" :slant normal :weight normal :height 173 :width normal)))))

;; -------------------------------------------------------------------
;; Modelica mode

;; (setq load-path (cons "~/.emacs_modes/modelica" load-path))
;; (add-to-list 'auto-mode-alist '("\.mo$" . modelica-mode))
;; (autoload 'modelica-mode "modelica-mode" "Modelica Editing Mode" t)

;; Enable Modelica browsing
;; (autoload 'mdc-browse "mdc-browse" "Modelica Class Browsing" t)
;; (autoload 'br-mdc "br-mdc" "Modelica Class Browsing" t)

;; -------------------------------------------------------------------
;; Graphiz dot

(org-babel-do-load-languages
 (quote org-babel-load-languages)
 (quote ((dot . t))))

;; -------------------------------------------------------------------
;; Michelson

;; (use-package deferred :ensure t)
;; (use-package exec-path-from-shell :ensure t)

;; (load "~/git/tezos/emacs/michelson-mode.el" nil t)
;; (setq michelson-client-command "tezos-client")
;; (setq michelson-alphanet nil)

;; -------------------------------------------------------------------
;; JavaScript

(setq js-indent-level 2)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Ubuntu Mono" :foundry "DAMA" :slant normal :weight normal :height 128 :width normal)))))

;; -------------------------------------------------------------------
;; Lilypond

(add-to-list 'load-path "~/.emacs_modes/lilypond")
(add-to-list 'auto-mode-alist '("\\.ly$" . lilypond-mode))
(autoload 'lilypond-mode "lilypond-mode" "Lilypond mode." t)
;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line
