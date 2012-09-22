;;; rcirc-robots.el --- robots based on the rcirc irc client

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: comm

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Building a simpler robot framework out of rcirc.

;;; Code:


(require 'rcirc)

(defun rcirc-text>channel (process channel text)
  "Send the TEXT to the CHANNEL attached to PROCESS.

This is the building block of automatic responses."
  (with-current-buffer
      (cdr (assoc target
                  (with-current-buffer
                      (process-buffer process)
                    rcirc-buffer-alist)))
    (goto-char (point-max))
    (insert text)
    (rcirc-send-input)))

(defun rcirc-robots-german-time (process sender response target text)
  "If asked for 'germantime' response with the time in Berlin."
  (when (string-match ".*\\germantime$" text)
    (rcirc-text>channel
     process target
     (format
      "the time in germany is %s"
      (let ((tz (getenv "TZ")))
        (unwind-protect
             (progn
               (setenv "TZ" "Europe/Berlin")
               (format-time-string "%H:%M"))
          (if tz
              (setenv "TZ" tz)
              (setenv "TZ" nil))))))))

;; Add the hook
(add-hook
 'rcirc-print-hooks
 'rcirc-robots-german-time)


(provide 'rcirc-robots)

;;; rcirc-robots.el ends here
