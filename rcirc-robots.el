;;; rcirc-robots.el --- robots based on the rcirc irc client

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: comm
;; Version: 0.0.2
;; Maintainer: Nic Ferrier <nferrier@ferrier.me.uk>
;; Created: 12th September 2012

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

(defvar rcirc-robot--process nil
  "Dynamic bound variable for robot send.")

(defvar rcirc-robot--channel nil
  "Dynamic bound variable for robot send")

(defun rcirc-robot-send (text)
  "Send TEXT to the current process and channel.

Robots can use this to send text back to the channel and process
that caused them to be invoked."
  (rcirc-text>channel
   rcirc-robot--process
   rcirc-robot--channel
   text))

(require 'anaphora)

(defun rcirc-robots-time (text place)
  "Get the time of a place and report it."
  (let ((places
         '(("Germany" . "Europe/Berlin")
           ("Berlin" . "Europe/Berlin")
           ("Hamburg" . "Europe/Berlin")
           ("England" . "Europe/London")
           ("London" . "Europe/London")
           ("Edinburgh" . "Europe/London")
           ("Manchester" . "Europe/London")
           ("Chicago" . "America/Chicago"))))
    (acond
      ((or
        (equal place "?")
        (equal place "help"))
       (rcirc-robot-send
        (format "places you can query for time %s"
                (kvalist->keys places))))
      ((assoc (capitalize place) places)
       (rcirc-robot-send
        (format
         "the time in %s is %s"
         (car it) ; the pair that assoc matched, the car's the place
         (let ((tz (getenv "TZ")))
           (unwind-protect
                (progn
                  (setenv "TZ" (cdr it))
                  (format-time-string "%H:%M"))
             (if tz
                 (setenv "TZ" tz)
                 (setenv "TZ" nil))))))))))

(defvar rcirc-robots--list
  (list
   (list :name "timezone"
         :version 1
         :regex "time \\([A-Za-\]+\\)"
         :function 'rcirc-robots-time))
  "The list of robots.

Each robot definition is a plist.  The plist has the following keys:

 :name the name of the robot
 :version the version of the robot definition, currently only version 1
 :regex a regex that will be used to match input and fire the robot
 :function will be called with the strings matched by the regex

When the function is evaluated the function `rcirc-robot-send' is
in scope to send text to the channel that caused the robot
invocation.")

;;;###autoload
(defun rcirc-robots--dispatcher (process sender response target text)
  "Loop through `rcirc-robots--list' attempting to dispatch to robots."
  (flet ((match-strings-all (&optional str)
           (let ((m (if str (match-data str) (match-data))))
             (loop for i
                from 0 to (- (/ (length m) 2) 1)
                collect (match-string i str)))))
    (loop for robot in rcirc-robots--list
       if (string-match (plist-get robot :regex) text)
       do (let ((rcirc-robot--process process)
                (rcirc-robot--channel target)
                (matches (match-strings-all text)))
            (apply (plist-get robot :function) matches)))))

;; Add the hook
(add-hook
 'rcirc-print-hooks
 'rcirc-robots--dispatcher)


;; More robots

(defun rcirc-robots-hammertime (&rest args)
  (let ((quotes (list
                 "READY THE ENORMOUS TROUSERS!"
                 "YOU CAN'T TOUCH THIS!")))
    (rcirc-robot-send (elt quotes (random (length quotes))))))

(add-to-list
 'rcirc-robots--list
 (list :name "hammertime"
       :version 1
       :regex "hammertime[?!]*"
       :function 'rcirc-robots-hammertime))

(defun rcirc-robots-insult (text user)
  (let ((adjectives (list
                    "stinky"
                    "tiny-minded"
                    "pea-brained"
                    "heavily lidded"
                    "muck minded"
                    "flat footed"))
        (nouns (list
                "bog warbler"use-hard-newlines
                "tin pincher"
                "yeti"
                "whoo-har")))
    (rcirc-robot-send
     (format "%s is a %s %s"
             user
             (elt adjectives (random (length adjectives)))
             (elt nouns (random (length nouns)))))))

(add-to-list
 'rcirc-robots--list
 (list :name "insult"
       :version 1
       :regex "^insult \\([A-Za-z0-9-]+\\)"
       :function 'rcirc-robots-insult))

(provide 'rcirc-robots)

;;; rcirc-robots.el ends here
