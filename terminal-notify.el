;;; terminal-notifier.el --- Send notification to notification center

;; Copyright © 2012 Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, 
;; Created: 2012-08-08
;; Last changed: 2012-08-10 16:37:55
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; 
;; Send notification to MacOSX notification center using
;; terminal-notification.app which can be downloaded from:
;;
;; https://github.com/alloy/terminal-notifier
;;

;;; Code:


(defvar terminal-notifier-app
  "/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"
  "Path to the terminal notifier binary.")

(defvar terminal-notifier-emacs-bundle-id "org.gnu.Emacs"
  "Emacs bundle ID. Could be found using shell command:
osascript -e 'id of app \"Emacs\"'")

(defun terminal-notifier-sentinel (proc change)
  "Sentinel to clean up process and remove notification if
needed."
  (when (eq (process-status proc) 'exit)
    (let ((status  (process-exit-status proc))
	  (timeout (process-get proc :timeout))
	  (id (process-get proc :id)))
      (if (not (eq 0 status))
	  (progn)
	(kill-buffer (process-buffer proc))
	(when (and timeout id (> timeout 0))
	  (run-at-time timeout nil
		       'terminal-notifier-run-cmd
		       `("-remove" ,id)))))))

(defun terminal-notifier-run-cmd (args &optional timeout id)
  "Low level function to run terminal-notifier. Should be used
directly (see `terminal-notifier-notify') ."
  (let* ((cmd-line `(,terminal-notifier-app
		     ,@args))
	 (cmd-buf (get-buffer-create
		   (format " Terminal-notifier %s" (random))))
	 (proc (apply 'start-process (car cmd-line)
		      cmd-buf (car cmd-line) (cdr cmd-line))))
    (process-put proc :timeout timeout)
    (process-put proc :id id)
    (set-process-sentinel proc 'terminal-notifier-sentinel)))

(defun terminal-notifier-notify (title message &optional timeout)
  "Display MESSAGE with TITLE in MacOSX notification center using
terminal-notify.app.

If TIMEOUT is positive, the notification is removed from the
notification-center after TIMEOUT seconds or 10 seconds if
TIMEOUT is nil."
  (let ((timeout (or timeout 10))
	(id (format "%s" (random))))
    (terminal-notifier-run-cmd
     `("-message" ,message "-title" ,title
       "-activate" ,terminal-notifier-emacs-bundle-id
       "-group"  ,id)
     timeout id)))

(defalias 'notify 'terminal-notifier-notify)

(defun terminal-notifier-notifications-notify (&rest params)
  "`notification-notify' compatibility."
  (terminal-notifier-notify (plist-get params :title)
			    (plist-get params :body)
			    (plist-get params :timeout)))

(defalias 'notifications-notify 'terminal-notifier-notifications-notify)


(provide 'terminal-notifier)

;; terminal-notifier.el ends here
