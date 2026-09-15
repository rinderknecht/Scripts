;; -*- emacs-lisp -*-

;; Configuration file for Emacs

;; -------------------------------------------------------------------
;; Useful Tips

;; To convert a buffer to UTF-8:
;; C-x RET f utf-8 RET
;; Then:
;; C-x C-s
;;
;; C-x C-+ Enlarge font
;; C-x C-- Shrink font
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
;; C-x 8 !       ¡
;; C-x 8 <       «
;; C-x 8 >       »

;; -------------------------------------------------------------------
;; Package management

(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/"))
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
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

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Ubuntu Sans Mono" :foundry "DAMA" :slant normal :weight regular :height 120 :width normal)))))

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
   '(lsp-mode boogie-friends rust-mode envrc kotlin-mode iedit json-mode exec-path-from-shell deferred use-package))
 '(safe-local-variable-values '((ispell-dictionary . "british")))
 '(save-place-mode t nil (saveplace))
 '(tool-bar-mode nil)
 '(tuareg-font-lock-symbols t)
 '(uniquify-buffer-name-style nil nil (uniquify)))

;; Main window geometry
;;
(setq default-frame-alist '((height . 145)(width . 79)))

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
(setq require-final-newline t) ;; Set to "nil" for the opposite.

;; Show carriage return and end of file characters (MS DOS text files)
;;
(setq inhibit-eol-conversion t) ;; Set to "nil" for the opposite.

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
  (lambda () (font-lock-add-keywords
              nil '(("\t" 0 'trailing-whitespace prepend)))))

;; Wrap long lines by word boundary
;;
(global-visual-line-mode 1) ;; 1 for on, 0 for off.

;; Electric buffer and no startup message
;;
(global-set-key (kbd "C-x C-b") 'electric-buffer-list)

(setq inhibit-startup-message t)

;; 8-bits display and input characters
;;
(add-hook 'text-mode-hook
  (lambda () (set-input-method "french-prefix")))

;; UTF-8 encoding
;;
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; No lock files (they mess with some build systems)
;;
(setq create-lockfiles nil)

;; -------------------------------------------------------------------
;; Spell checker in Emacs is `aspell'
;;
(let ((aspell (executable-find "aspell")))
  (when aspell (setq ispell-program-name aspell)))

(setq ispell-dictionary "british")

;; -------------------------------------------------------------------
;; GNU Makefile mode
;;
(add-to-list 'auto-mode-alist '("\\`Makefile\\(\\.in\\)?\\'" . makefile-gmake-mode))

(add-hook 'makefile-gmake-mode-hook
          (lambda () (setq makefile-gmake-indent 2)))

;; -------------------------------------------------------------------
;; Java mode
;;
(global-font-lock-mode t)
(add-hook 'java-mode-hook (lambda () (setq c-basic-offset 2
                                      tab-width 2
                                      indent-tabs-mode nil)))

;; -------------------------------------------------------------------
;; Prolog mode (SWI-Prolog)
;;
(setq auto-mode-alist
  (append '(("\\.pl$" . prolog-mode)
            ("\\.P$"  . prolog-mode)) auto-mode-alist))

(setq prolog-program-name "pl")
(setq prolog-consult-string "[user].\n")
(setq prolog-indent-width 4)

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
;; (add-to-list 'load-path "~/.emacs_modes/markdown")
;; (add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
;; (autoload 'markdown-mode "markdown-mode" "Markdown mode." t)

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
(setq tuareg-font-lock-symbols-alist
      `(("fun" . ,(decode-char 'ucs 955))
        ("sqrt" . ,(decode-char 'ucs 8730))
;;        ("not" . ,(decode-char 'ucs 172))
;;        ("or" . ,(decode-char 'ucs 8744)); 'LOGICAL OR' (U+2228)
        ("&&" . ,(decode-char 'ucs 8743)); 'LOGICAL AND' (U+2227)
        ("||" . ,(decode-char 'ucs 8744))
        ("[|" . ,(decode-char 'ucs 12314)) ;;〚
        ("|]" . ,(decode-char 'ucs 12315)) ;; 〛
        ("*." . ,(decode-char 'ucs 215))
        ("/." . ,(decode-char 'ucs 247))
        ("->" . ,(decode-char 'ucs 8594))
        ("<-" . ,(decode-char 'ucs 8592))
        ("<=" . ,(decode-char 'ucs 8804))
        (">=" . ,(decode-char 'ucs 8805))
        ("<>" . ,(decode-char 'ucs 8800))
        ("==" . ,(decode-char 'ucs 8801))
        ("!=" . ,(decode-char 'ucs 8802))
;;        ("<=>" . ,(decode-char 'ucs 8660))
;;        (":=" . ,(decode-char 'ucs 8656))
;;        ("infinity" . ,(decode-char 'ucs 8734))
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
        ("'p" . ,(decode-char 'ucs 960))
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

(let ((merlin-path (getenv "MERLIN_PATH"))) ;; Set by flake.nix
  (if (not merlin-path)
    ;; Not in Nix shell
    (progn
      (require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
      (let ((opam-share (ignore-errors (car (process-lines "OPAMSWITCH=default" "opam" "var" "share")))))
         (when (and opam-share (file-directory-p opam-share))
         (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share)))))
    ;; In Nix shell
    (progn
      (add-to-list 'load-path (expand-file-name "share/emacs/site-lisp" merlin-path)))))

(autoload 'merlin-mode "merlin" nil t nil)
(add-hook 'tuareg-mode-hook 'merlin-mode t)
(add-hook 'caml-mode-hook 'merlin-mode t)
(setq merlin-ac-setup 'easy)

;; -------------------------------------------------------------------
;; Email mode
;;
;; (add-to-list 'auto-mode-alist'("\\.eml" . text-mode))

;; -------------------------------------------------------------------
;; nXML mode for XSLT and XML (default in Emacs nowadays)
;;
;; (add-to-list 'auto-mode-alist
;;             '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\)\\'" . nxml-mode))

;; -------------------------------------------------------------------
;; Erlang mode
;;
(add-to-list 'load-path "~/.emacs_modes/erlang")
(add-to-list 'auto-mode-alist '("\\.erl$" . erlang-mode))
(autoload 'erlang-mode "erlang" "Erlang mode." t)

;; TABs are changed into spaces.
;;
(add-hook 'erlang-mode-hook (lambda () (setq indent-tabs-mode nil)))

;; -------------------------------------------------------------------
;; Scala mode
;;
;; (add-to-list 'load-path "~/.emacs_modes/scala")
;; (require 'scala-mode-auto)

;; -------------------------------------------------------------------
;; Graphiz dot

(org-babel-do-load-languages
 (quote org-babel-load-languages)
 (quote ((dot . t))))

;; -------------------------------------------------------------------
;; Michelson
;;
;; (use-package deferred :ensure t)
;; (use-package exec-path-from-shell :ensure t)
;; (load "~/git/tezos/emacs/michelson-mode.el" nil t)
;; (setq michelson-client-command "tezos-client")
;; (setq michelson-alphanet nil)

;; -------------------------------------------------------------------
;; JavaScript
;;
;; (setq js-indent-level 2)

;; -------------------------------------------------------------------
;; Lilypond
;;
(setq load-path (append (list (expand-file-name "~/site-lisp")) load-path))

;;(add-to-list 'load-path "~/.emacs_modes/lilypond")
;;(add-to-list 'auto-mode-alist '("\\.ly$" . lilypond-mode))
;;(autoload 'lilypond-mode "lilypond-mode" "Lilypond mode." t)

;; -------------------------------------------------------------------
;; envrc
;;
;; (add-hook 'after-init-hook 'envrc-global-mode)

;; -------------------------------------------------------------------
;; Rust
;;
(add-to-list 'load-path "~/.emacs_modes/rust-mode")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))

;; -------------------------------------------------------------------
;; JsLIGO
;;
;; (add-to-list 'auto-mode-alist '("\\.jsligo$" . js-mode))

;; -------------------------------------------------------------------
;; YAML
;;
(add-to-list 'load-path "~/.emacs_modes/yaml")
(autoload 'yaml-mode "yaml-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))

;; -------------------------------------------------------------------
;; CRAM tests
;;
(add-to-list 'load-path "~/.emacs_modes/cram")
(autoload 'cram-mode "cram-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.t$" . cram-mode))

;; -------------------------------------------------------------------
;; Dafny
;;
(require 'flycheck)
(require 'dafny-mode)
(setq flycheck-dafny-executable "/home/rinderkn/tools/src/dafny/dafny")

;; (add-to-list 'load-path "~/.emacs_modes/dafny/emacs")
;; (autoload 'dafny-mode "boogie-friends" nil t)
;; (add-to-list 'auto-mode-alist '("\\.dfy$" . dafny-mode))

;; -------------------------------------------------------------------
;; Lean
;;
(add-to-list 'load-path "~/.emacs_modes/lean4-mode")
(require 'lsp-mode)
(require 'lean4-mode)
