;;; rcirc-robots.el --- robots based on the rcirc irc client

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: comm
;; Version: 0.0.2
;; Maintainer: Nic Ferrier <nferrier@ferrier.me.uk>
;; Created: 12th September 2012
;; Package-Requires: ((kv "0.0.6"))

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
(require 'cl)

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
           ("Brazil" . "America/Sao_Paulo")
           ("Sao Paulo" . "America/Sao_Paulo")
           ("Sao-Paulo" . "America/Sao_Paulo")
           ("SaoPaulo" . "America/Sao_Paulo")
           ("Chicago" . "America/Chicago")
           ("Los Angeles" . "America/Los_Angeles")
           ("Los-Angeles" . "America/Los_Angeles")
           ("San Francisco" . "America/Los_Angeles")
           ("Chennai" . "Asia/Kolkata")
           ("Bangalore" . "Asia/Kolkata")
           ("Pune" . "Asia/Kolkata")
           ("India" . "Asia/Kolkata")
           ("Delhi" . "Asia/Kolkata")
           ("Agartala" . "Asia/Kolkata"))))
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

(defun ask-doctor (text)
  (with-current-buffer (or
                        (get-buffer "*doctor*")
                        (progn
                          (doctor)
                          (get-buffer "*doctor*")))
    (goto-char (point-max))
    (insert "I'm feeling unwell\n")
    (doctor-ret-or-read t)
    (let ((p (point)))
      (doctor-ret-or-read t)
      (message (buffer-substring p (point-max))))))

(defvar rcirc-robots--list
  (list)
  "The list of robots.

Each robot definition is a plist.  The plist has the following keys:

 :name the name of the robot
 :version the version of the robot definition, currently only version 1
 :regex a regex that will be used to match input and fire the robot
 :function will be called with the strings matched by the regex

When the function is evaluated the function `rcirc-robot-send' is
in scope to send text to the channel that caused the robot
invocation.")

(defun* rcirc-robots-add-function (&key
                                   name
                                   version
                                   regex
                                   function)
  "Add the specified robot to the list."
  (condition-case err
      (progn
        (mapcar
         (lambda (p)
           (when (equal (plist-get p :name) name)
             (error "%s exists" name)))
         rcirc-robots--list)
        ;; Install the bot
        (add-to-list
         'rcirc-robots--list
         (list  :name name
                :version version
                :regex regex
                :function function)))
    (error nil)))

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
;(remove-hook
; 'rcirc-print-hooks
; 'rcirc-robots--dispatcher)


;; More robots

(defun rcirc-robots-maker (&args)
  (rcirc-robot-send
   "I am [[https://github.com/nicferrier/rcirc-robots|a robot]]"))

(defun rcirc-robots-hammertime (&rest args)
  (let ((quotes (list
                 "READY THE ENORMOUS TROUSERS!"
                 "YOU CAN'T TOUCH THIS!")))
    (rcirc-robot-send (elt quotes (random (length quotes))))))

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

(defun rcirc-robots-doctor (text)
  (rcirc-robot-send
   (ask-doctor text)))

(rcirc-robots-add-function
 :name "timezone" :version 1 :regex "time \\([A-Za-z\ -]+\\)"
 :function 'rcirc-robots-time))

(rcirc-robots-add-function
 :name "maker" :version 1 :regex "who are you?"
 :function 'rcirc-robots-maker)

(rcirc-robots-add-function
 :name "hammertime" :version 1 :regex "hammertime[?!]*"
 :function 'rcirc-robots-hammertime)

(rcirc-robots-add-function
 :name "insult" :version 1 :regex "^insult \\([A-Za-z0-9-]+\\)"
 :function 'rcirc-robots-insult)

(add-to-list
 'rcirc-robots--list
 (list :name "doctor"
       :version 1
       :regex "doctor \\(.*\\)"
       :function 'rcirc-robots-doctor))

(provide 'rcirc-robots)

;;; rcirc-robots.el ends here
