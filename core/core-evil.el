;;; core-evil.el --- the root of all evil
;; see lib/evil-defuns.el

(use-package evil
  :init
  ;; highlight matching delimiters where it's important
  (defun show-paren-mode-off () (show-paren-mode -1))
  (add-hook! evil-insert-state-entry    'show-paren-mode)
  (add-hook! evil-insert-state-exit     'show-paren-mode-off)
  (add-hook! evil-visual-state-entry    'show-paren-mode)
  (add-hook! evil-visual-state-exit     'show-paren-mode-off)
  (add-hook! evil-motion-state-entry    'show-paren-mode)
  (add-hook! evil-motion-state-exit     'show-paren-mode-off)
  (add-hook! evil-operator-state-entry  'show-paren-mode)
  (add-hook! evil-operator-state-exit   'show-paren-mode-off)

  ;; Disable highlights on insert-mode
  (add-hook! evil-insert-state-entry 'evil-ex-nohighlight)

  (add-hook! undo-tree-mode (diminish 'undo-tree-mode))
  ;; Always ensure evil-shift-width is consistent with tab-width
  (add-hook! evil-local-mode (setq evil-shift-width tab-width))
  :config
  (setq evil-magic                t
        evil-want-C-u-scroll      t  ; enable C-u for scrolling
        evil-ex-visual-char-range t  ; column range for ex commands
        evil-want-fine-undo       nil
        evil-want-visual-char-semi-exclusive nil
        evil-ex-search-vim-style-regexp t
        evil-ex-interactive-search-highlight 'selected-window

        ;; Color-coded state cursors
        evil-normal-state-cursor  '("white" box)
        evil-emacs-state-cursor   '("cyan" bar)
        evil-insert-state-cursor  '("white" bar)
        evil-visual-state-cursor  '("white" hollow)
        evil-iedit-state-cursor   '("orange" box))

  (evil-mode 1)
  (evil-select-search-module 'evil-search-module 'evil-search)

  (bind! :map evil-command-window-mode-map :n [escape] 'kill-buffer-and-window)

  (defadvice evil-ex-hl-do-update-highlight (around evil-ex-hl-shut-up activate)
    "Silence 'Error running timer `evil-ex-hl-do-update-highlight': (error
\"Invalid use of `\\' in replacement text\") errors.

See `https://bitbucket.org/lyro/evil/issue/527'"
    (ignore-errors ad-do-it))

  ;; modes to map to different default states
  (dolist (mode-map '((cider-repl-mode   . emacs)
                      (comint-mode       . emacs)
                      (term-mode         . emacs)
                      (fundamental-mode  . motion)
                      (help-mode         . normal)
                      (message-mode      . normal)
                      (compilation-mode  . normal)
                      (text-mode         . normal)))
    (evil-set-initial-state `,(car mode-map) `,(cdr mode-map)))

  (progn ; evil hacks
    (defadvice evil-force-normal-state (before evil-esc-quit activate)
      (ignore-errors
        (popwin:close-popup-window)                 ; close popups, if any
        (evil-search-highlight-persist-remove-all)  ; turn off highlights
        (evil-ex-nohighlight)
        ;; Exit minibuffer if alive
        (if (minibuffer-window-active-p (minibuffer-window))
            (narf/minibuffer-quit))))

    ;; Jump to new splits
    (defadvice evil-window-split (after evil-window-split-jump activate)
      (evil-window-down 1))
    (defadvice evil-window-vsplit (after evil-window-vsplit-jump activate)
      (evil-window-right 1))

    ;; Restore vimmish ex-mode keymaps to isearch
    ;; Hide keystroke display while isearch is active
    (add-hook! isearch-mode     (setq echo-keystrokes 0))
    (add-hook! isearch-mode-end (setq echo-keystrokes 0.02))
    (bind! :map isearch-mode-map
           "C-r" nil

           "C-r %" (λ (narf/isearch-paste-from-register ?%))
           "C-r #" (λ (narf/isearch-paste-from-register ?#))
           "C-r /" (λ (narf/isearch-paste-from-register ?/))
           "C-r :" (λ (narf/isearch-paste-from-register ?:))
           "C-r ." (λ (narf/isearch-paste-from-register ?.))
           "C-r -" (λ (narf/isearch-paste-from-register ?-))
           "C-r _" (λ (narf/isearch-paste-from-register ?_))
           "C-r =" (λ (narf/isearch-paste-from-register ?=))
           "C-r +" 'narf/isearch-paste-from-clipboard

           "C-w"   'narf/isearch-delete-word
           "C-u"   'narf/isearch-delete-line
           "M-v"   'narf/isearch-paste-from-clipboard)))

;; evil plugins
(use-package evil-anzu)

(use-package evil-commentary
  :diminish evil-commentary-mode
  :commands (evil-commentary
             evil-commentary-yank
             evil-commentary-line)
  :config (evil-commentary-mode 1))

(use-package evil-ex-registers
  :commands (evil-get-spec-register
             evil-ex-paste-from-register))

(use-package evil-exchange
  :commands evil-exchange
  :config
  (advice-add 'evil-force-normal :after 'narf*evil-exchange-off))

(use-package evil-iedit-state
  :functions (iedit-current-occurrence-string iedit-restrict-region)
  :commands (evil-iedit-state evil-iedit-state/iedit-mode)
  :config
  (bind! ; Don't interfere with evil-snipe
   :I :unset "s"
   :I :unset "S"
   :I "V"   'evil-visual-line
   :I "C"   'evil-iedit-state/substitute  ; instead of s/S
   :I "za"  'iedit-toggle-unmatched-lines-visible
   :v "SPC" 'narf:iedit-restrict-to-region))

(use-package evil-indent-textobject
  :commands (evil-indent-i-indent
             evil-indent-a-indent
             evil-indent-a-indent-lines)
  :init
  (bind! :map evil-inner-text-objects-map
         "i" 'evil-indent-i-indent
         "i" 'evil-indent-a-indent
         "I" 'evil-indent-a-indent-lines))

(use-package evil-jumper
  :init
  (setq evil-jumper-file (! (concat narf-temp-dir "jumplist"))
        evil-jumper-auto-center t
        evil-jumper-auto-save-interval 3600))

(use-package evil-matchit
  :commands (evilmi-jump-items global-evil-matchit-mode)
  :config   (global-evil-matchit-mode 1))

(use-package evil-numbers
  :commands (evil-numbers/inc-at-pt
             evil-numbers/dec-at-pt))

(use-package evil-search-highlight-persist
  :config (global-evil-search-highlight-persist t))

(use-package evil-snipe
  :diminish evil-snipe-mode
  :commands (evil-snipe-s evil-snipe-S
             evil-snipe-x evil-snipe-X
             evil-snipe-f evil-snipe-F
             evil-snipe-t evil-snipe-T
             evil-snipe-repeat evil-snipe-repeat-reverse)
  :init
  (bind! :m "s" 'evil-snipe-s
         :m "S" 'evil-snipe-S
         :m "f" 'evil-snipe-f
         :m "F" 'evil-snipe-F
         :m "t" 'evil-snipe-t
         :m "T" 'evil-snipe-T
         :o "z" 'evil-snipe-s
         :o "Z" 'evil-snipe-S
         :o "x" 'evil-snipe-x
         :o "X" 'evil-snipe-X)
  (define-key evil-normal-state-map "s" nil)
  (define-key evil-normal-state-map "S" nil)
  :config
  (setq-default
   evil-snipe-smart-case t
   evil-snipe-scope 'line
   evil-snipe-repeat-scope 'buffer
   evil-snipe-override-evil-repeat-keys nil
   evil-snipe-symbol-groups '((?\[ "[[{(]")
                              (?\] "[]})]")))
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

(use-package evil-space
  :diminish (evil-space-mode . "_")
  :init (setq evil-space-auto-setup nil)
  :config
  (evil-space-mode 1)

  (evil-space-setup "/" "n" "N")
  (evil-space-setup "?" "N" "n")

  (after! evil-snipe
    (evil-space-setup 'evil-snipe-f 'evil-snipe-repeat 'evil-snipe-repeat-reverse)
    (evil-space-setup 'evil-snipe-F 'evil-snipe-repeat 'evil-snipe-repeat-reverse)
    (evil-space-setup 'evil-snipe-t 'evil-snipe-repeat 'evil-snipe-repeat-reverse)
    (evil-space-setup 'evil-snipe-T 'evil-snipe-repeat 'evil-snipe-repeat-reverse)
    (evil-space-setup 'evil-snipe-s 'evil-snipe-repeat 'evil-snipe-repeat-reverse)
    (evil-space-setup 'evil-snipe-S 'evil-snipe-repeat 'evil-snipe-repeat-reverse))

  (after! evil-visualstar
    (evil-space-setup 'evil-visualstar/begin-search-forward "n" "N")
    (evil-space-setup 'evil-visualstar/begin-search-backward "n" "N")))

(use-package evil-surround
  :commands (global-evil-surround-mode
             evil-surround-edit
             evil-Surround-edit
             evil-surround-region)
  :config
  (global-evil-surround-mode 1)
  ;; Escaped surround characters
  (push '(?\\ . narf/evil-surround-escaped) evil-surround-pairs-alist))

(use-package evil-visualstar
  :commands (global-evil-visualstar-mode
             evil-visualstar/begin-search
             evil-visualstar/begin-search-forward
             evil-visualstar/begin-search-backward)
  :config
  (global-evil-visualstar-mode 1))

(provide 'core-evil)
;;; core-evil.el ends here
