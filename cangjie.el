;;; cangjie.el --- retrieve cangjie code for han characters  -*- lexical-binding: t; -*-

;; Authors: Kisaragi Hiu <mail@kisaragi-hiu.com>
;; URL: https://gitlab.com/kisaragi-hiu/cangjie.el
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (s "1.12.0") (dash "2.14.1"))
;; Keywords: cangjie, lookup, writing, education

;;; Commentary:

;; This package is for quick retrieval of Cangjie codes of Han characters.
;; Setup `cangjie-source' to point to a [RIME](//rime.im) Cangjie dictionary,
;; or 'wiktionary to grab the code from Wiktionary.

;;; Code:

(require 's)
(require 'dash)

;; TODO: I don't know how to use defcustom.
(defvar cangjie-source "/usr/share/rime-data/cangjie5.dict.yaml"
  "RIME dictionary to lookup the character's code in.

When this is set to the symbol `wiktionary' or anything that's not a valid path
to a RIME dictionary, grep the Wiktionary page for the character instead.")

(defun cangjie--grep (file s)
  "Grep wrapper.

Grab lines from FILE containing S."
  (shell-command-to-string (concat "grep " s " " file)))

(defun cangjie--grep-line (file s)
  "Grab lines from FILE containing S, and return them as a list."
  (->> (cangjie--grep file s)
       s-trim
       (s-split "\n")))

(defun cangjie--file-contains? (file s)
  "Does FILE contain S?"
  (not (s-equals? "" (shell-command-to-string (concat "grep " s " " file)))))

(defun cangjie--valid-rime-dict? (val)
  "Check if VAL is a path to a valid RIME dictionary."
  (and (stringp val)
       (file-exists-p val)
       (s-suffix? ".yaml" val)
       (cangjie--file-contains? val "name:")
       (cangjie--file-contains? val "use_preset_vocabulary:")))

(defconst cangjie--abc-to-han-hash
  #s(hash-table
     size 60
     test equal
     data ("a" "日" "b" "月" "c" "金" "d" "木" "e" "水" "f" "火"
           "g" "土" "h" "竹" "i" "戈" "j" "十" "k" "大" "l" "中"
           "m" "一" "n" "弓" "o" "人" "p" "心" "q" "手" "r" "口"
           "s" "尸" "t" "廿" "u" "山" "v" "女" "w" "田" "x" "難"
           "y" "卜" "z" "重"))
  "Hash table mapping alphabetical Canjie representation to Han character representation.")

(defun cangjie--abc-to-han (abc)
  "Convert alphabetical Cangjie code representation ABC into Han characters."
  (->> (downcase abc)
       (s-split "")
       (--map (gethash it cangjie--abc-to-han-hash))
       (s-join "")))

(defun cangjie (han)
  "Retrieve Cangjie code for the HAN character."
  (cond ((cangjie--valid-rime-dict? cangjie-source)
         ;; take cangjie encoding from RIME dictionary
         (->> (cangjie--grep-line cangjie-source han)
              (--filter (not (s-prefix? "#" it)))
              (s-join "")
              (s-split "\t")
              second
              cangjie--abc-to-han))
        ((eq cangjie-source 'wiktionary)
         ;; Try to extract encoding from grep'd wiktionary text
         (->> (shell-command-to-string
               (concat "curl --silent https://zh.wiktionary.org/wiki/" han
                       " | grep 仓颉"))
              (s-replace-regexp "^.*：" "")
              s-trim
              (s-replace-regexp "<.*>$" "")
              cangjie--abc-to-han))
        (t
         ;; Fallback
         (shell-command-to-string
          (concat "curl --silent https://zh.wiktionary.org/wiki/" han
                  " | grep 仓颉")))))

(provide 'cangjie)
;;; cangjie.el ends here