(use-package org-bullets
  :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode))))

(setq org-src-window-setup 'current-window)
(add-hook 'org-mode-hook 'org-indent-mode)

(add-to-list 'org-structure-template-alist
	     '("el" "#+BEGIN_SRC emacs-lisp\n?\n#+END_SRC"))

(use-package org-re-reveal-ref
    :ensure t)

;;  (setq org-reveal-root "http://cdn.jsdelivr.net/reveal.js/3.0.0/")
;;  (setq org-reveal-mathjax t)

;;  (use-package htmlize
;;    :ensure t)

(use-package exwm
  :ensure t
  :config
  (require 'exwm-config)
  (exwm-config-default))

;;(require 'exwm-systemtray)
;;(exwm-systemtray-enable)

(global-set-key (kbd "s-k") 'exwm-workspace-delete)
(global-set-key (kbd "s-w") 'exwm-workspace-swap)

(use-package exwm-edit
  :ensure t
  :config
  (defun ag-exwm/on-exwm-edit-compose ()
    (funcall 'markdown-mode))

  (add-hook 'exwm-edit-compose-hook 'ag-exwm/on-exwm-edit-compose))

;; https://emacs.stackexchange.com/questions/33326/how-do-i-cut-and-paste-effectively-between-applications-while-using-exwm
(defun fhd/exwm-input-line-mode ()
  "Set exwm window to line-mode and show mode line"
  (call-interactively #'exwm-input-grab-keyboard)
  (exwm-layout-show-mode-line))

(defun fhd/exwm-input-char-mode ()
  "Set exwm window to char-mode and hide mode line"
  (call-interactively #'exwm-input-release-keyboard)
  (exwm-layout-hide-mode-line))

(defun fhd/exwm-input-toggle-mode ()
  "Toggle between line- and char-mode"
  (interactive)
  (with-current-buffer (window-buffer)
    (when (eq major-mode 'exwm-mode)
      (if (equal (second (second mode-line-process)) "line")
          (fhd/exwm-input-char-mode)
        (fhd/exwm-input-line-mode)))))

(exwm-input-set-key (kbd "s-i") #'fhd/exwm-input-toggle-mode)

(defun fhd/toggle-exwm-input-line-mode-passthrough ()
  (interactive)
  (if exwm-input-line-mode-passthrough
    (progn
      (setq exwm-input-line-mode-passthrough nil)
      (message "App receives all the keys now (with some simulation)"))
   (progn
     (setq exwm-input-line-mode-passthrough t)
     (message "emacs receives all the keys now")))
  (force-mode-line-update))

(exwm-input-set-key (kbd "s-p") 'fhd/toggle-exwm-input-line-mode-passthrough)

(add-hook 'exwm-manage-finish-hook
  (lambda () (call-interactively #'exwm-input-release-keyboard)
     (exwm-layout-hide-mode-line)))

(defalias 'yes-or-no-p 'y-or-n-p)

(display-time-mode 1)

(use-package which-key
  :ensure t
  :init
  (which-key-mode))

(setq scroll-conservatively 100)

(when window-system (global-hl-line-mode t))
(use-package beacon
  :ensure t
  :init
  (beacon-mode 1))

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

(when window-system
  (use-package pretty-mode
    :ensure t
    :config
    (global-pretty-mode t)))

(use-package rainbow-mode
  :ensure t
  :init (add-hook 'prog-mode-hook 'rainbow-mode))

(use-package rainbow-delimiters
  :ensure t
  :init
  (rainbow-delimiters-mode))

(line-number-mode 1)
(column-number-mode 1)

(global-set-key [remap goto-line] 'goto-line-with-feedback)

(defun goto-line-with-feedback ()
  "Show line numbers temporarily, while prompting for the line number input"
  (interactive)
  (unwind-protect
      (progn
        (linum-mode 1)
        (goto-line (read-number "Goto line: ")))
    (linum-mode -1)))

(defvar my-term-shell "/bin/bash")
(defadvice ansi-term (before force-bash)
  (interactive (list my-term-shell)))
(ad-activate 'ansi-term)

(defun comint-delchar-or-eof-or-kill-buffer (arg)
  (interactive "p")
  (if (null (get-buffer-process (current-buffer)))
      (kill-buffer)
    (comint-delchar-or-maybe-eof arg)))

(add-hook 'shell-mode-hook
          (lambda ()
            (define-key shell-mode-map
              (kbd "C-d") 'comint-delchar-or-eof-or-kill-buffer)))

(setq backup-directory-alist
      `(("." . ,(expand-file-name
                 (concat user-emacs-directory "backups")))))

(setq vc-make-backup-files t)

(use-package sudo-edit
  :ensure t
  :bind ("C-x M-s" . sudo-edit))

(use-package saveplace
  :ensure t
  :init
  (setq-default save-place t)
  (setq save-place-file (expand-file-name ".places" user-emacs-directory)))

(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(global-set-key (kbd "C-x C-r") 'rename-current-buffer-file)

(defun delete-current-buffer-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (y-or-n-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

(global-set-key (kbd "C-x C-k") 'delete-current-buffer-file)

(global-set-key (kbd "<s-return>") 'ansi-term)

(setq ido-enable-flex-matching nil)
(setq ido-create-new-buffer 'always)
(setq ido-everywhere t)
(ido-mode 1)

(use-package ido-vertical-mode
  :ensure t
  :init
  (ido-vertical-mode 1))
(setq ido-vertical-define-keys 'C-n-and-C-p-only)

(use-package smex
  :ensure t
  :init (smex-initialize)
  :bind
  ("M-x" . smex))

(global-set-key (kbd "C-x C-b") 'ido-switch-buffer)

(global-set-key (kbd "C-x b") 'ibuffer)

(setq ibuffer-expert t)

(use-package avy
  :ensure t
  :init
  (setq avy-timeout-seconds 0.3)
  (setq avy-all-windows 'all-frames)
  :bind
  ("M-s" . avy-goto-char-timer))

(use-package switch-window
  :ensure t
  :config
  (setq switch-window-input-style 'minibuffer)
  (setq switch-window-increase 4)
  (setq switch-window-threshold 2)
  (setq switch-window-shortcut-style 'qwerty)
  (setq switch-window-qwerty-shortcuts
	'("a" "s" "d" "f" "j" "k" "l"))
  :bind
  ([remap other-window] . switch-window))

(defun split-and-follow-horizontally ()
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))
(global-set-key (kbd "C-x 2") 'split-and-follow-horizontally)

(defun split-and-follow-vertically ()
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))
(global-set-key (kbd "C-x 3") 'split-and-follow-vertically)

(global-subword-mode 1)

(setq electric-pair-pairs '(
			    (?\( . ?\))
			    (?\[ . ?\])
			    (?\{ . ?\})
			    (?\" . ?\")
			    ))
(electric-pair-mode t)

(defun kill-whole-word()
  (interactive)
  (backward-word)
  (kill-word 1))
(global-set-key (kbd "C-c C-w") 'kill-whole-word)

(use-package hungry-delete
  :ensure t
  :config (global-hungry-delete-mode))

(defun kill-current-buffer ()
  (interactive)
  (kill-buffer (current-buffer)))
(global-set-key (kbd "C-x k") 'kill-current-buffer)

(defun copy-whole-line ()
  (interactive)
  (save-excursion
    (kill-new
     (buffer-substring
      (point-at-bol)
      (point-at-eol)))))
(global-set-key (kbd "C-c C-y") 'copy-whole-line)

(defun kill-all-buffers ()
  (interactive)
  (mapc 'kill-buffer (buffer-list)))
(global-set-key (kbd "C-M-s-k") 'kill-all-buffers)

(use-package popup-kill-ring
  :ensure t
  :bind ("M-y" . popup-kill-ring))

(use-package swiper
  :ensure t
  :bind ("C-s" . swiper))

(use-package mark-multiple
  :ensure t
  :bind ("C-c q" . 'mark-next-like-this))

(use-package expand-region
  :ensure t
  :bind ("C-q" . er/expand-region))

(defun open-line-below ()
  (interactive)
  (end-of-line)
  (newline)
  (indent-for-tab-command))

(defun open-line-above ()
  (interactive)
  (beginning-of-line)
  (newline)
  (forward-line -1)
  (indent-for-tab-command))

(global-set-key (kbd "<C-return>") 'open-line-below)
(global-set-key (kbd "<C-S-return>") 'open-line-above)

(setq ring-bell-function 'ignore)

;;  (use-package dashboard
;;    :ensure t
;;    :config
;;    (dashboard-setup-startup-hook)
;;    (setq dashboard-items '(recents . 10))
;;    (setq dashboard-banner-logo-title "egyb2h9"))

(defun config-visit ()
  (interactive)
  (find-file "~/.emacs.d/config.org"))
(global-set-key (kbd "C-c e") 'config-visit)

(defun config-reload ()
  (interactive)
  (org-babel-load-file (expand-file-name "~/.emacs.d/config.org")))
(global-set-key (kbd "C-c r") 'config-reload)

(use-package  try
  :ensure  t)

(use-package company
  :ensure t
  :init
  (add-hook 'after-init-hook 'global-company-mode))

(use-package company-terraform
  :ensure t
  :init
  (company-terraform-init))

(use-package bash-completion
:ensure t
:init
(add-hook 'shell-dynamic-complete-functions
	'bash-completion-dynamic-complete))

(use-package spaceline
  :ensure t
  :config
  (require ' spaceline-config)
  (setq powerline-default-separator (quote arrow))
  (spaceline-spacemacs-theme))

(use-package diminish
  :ensure t
  :init
  (diminish 'hungry-delete-mode)
  (diminish 'beacon-mode)
  (diminish 'which-key-mode)
  (diminish 'subword-mode)
  (diminish 'elisp-slime-nav-mode)
  (diminish 'rainbow-mode))

(use-package dmenu
  :ensure t
  :bind
  ("M-C-d" . 'dmenu))

(use-package symon
  :ensure t
  :bind
  ("M-C-s-m" . symon-mode))

(use-package emms
  :ensure t
  :config
    (require 'emms-setup)
    (require 'emms-player-mpd)
    (emms-all) ; don't change this to values you see on stackoverflow questions if you expect emms to work
    (setq emms-seek-seconds 5)
    (setq emms-player-list '(emms-player-mpd))
    (setq emms-info-functions '(emms-info-mpd))
    (setq emms-player-mpd-server-name "localhost")
    (setq emms-player-mpd-server-port "6601")
  :bind
    ("s-m p" . emms)
    ("s-m b" . emms-smart-browse)
    ("s-m r" . emms-player-mpd-update-all-reset-cache)
    ("<XF86AudioPrev>" . emms-previous)
    ("<XF86AudioNext>" . emms-next)
    ("<XF86AudioPlay>" . emms-pause)
    ("<XF86AudioStop>" . emms-stop))

(setq mpc-host "localhost:6601")

(defun mpd/start-music-daemon ()
  "Start MPD, connects to it and syncs the metadata cache."
  (interactive)
  (shell-command "mpd")
  (mpd/update-database)
  (emms-player-mpd-connect)
  (emms-cache-set-from-mpd-all)
  (message "MPD Started!"))
(global-set-key (kbd "s-m c") 'mpd/start-music-daemon)

(defun mpd/kill-music-daemon ()
  "Stops playback and kill the music daemon."
  (interactive)
  (emms-stop)
  (call-process "killall" nil nil nil "mpd")
  (message "MPD Killed!"))
(global-set-key (kbd "s-m k") 'mpd/kill-music-daemon)

(defun mpd/update-database ()
  "Updates the MPD database synchronously."
  (interactive)
  (call-process "mpc" nil nil nil "update")
  (message "MPD Database Updated!"))
(global-set-key (kbd "s-m u") 'mpd/update-database)

(use-package terraform-mode
  :ensure t
  :config
  (add-hook 'terraform-mode-hook #'terraform-format-on-save-mode))
