import XMonad

import XMonad.Actions.NoBorders

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.EwmhDesktops

import XMonad.Layout.Dishes
import XMonad.Layout.LayoutHints
import XMonad.Layout.NoBorders
import XMonad.Layout.Reflect
import XMonad.Layout.Spacing
import XMonad.Layout.Spiral

import XMonad.Util.EZConfig
import XMonad.Util.Run

import qualified DBus as D
import qualified DBus.Client as D
import qualified Codec.Binary.UTF8.String as UTF8
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

import System.IO
import Control.Concurrent

import Data.List

-- Define workspaces
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

-- Define layout symbols
myLayoutPrinter :: String -> String
myLayoutPrinter "Full" = "[ ]"
myLayoutPrinter "Tall" = "[]-"
myLayoutPrinter "ReflectX Tall" = "-[]"
myLayoutPrinter "Mirror Tall" = "[V]"
myLayoutPrinter "ReflectY Mirror Tall" = "[^]"
myLayoutPrinter "Spiral" = "(@)"
myLayoutPrinter x = "==="

-- Define layout
-- myLayout = avoidStruts layoutHints(tiled ||| Mirror tiled ||| Full)
myLayout = avoidStruts(tiled ||| Mirror tiled ||| dishes ||| Full)
   where
      tiled = Tall nmaster delta ratio
      nmaster = 1
      ratio = 2/3
      delta = 5/100
      dishes = Dishes 2 (1/6)
      mySpiral = spiral (6/7)
      myReverseTiled = reflectHoriz $ tiled
      myReverseMirrorTiled = reflectVert $ Mirror tiled

myManageHook = (composeAll . concat $
    [ [manageDocks]
    , [className =? c --> hasBorder False  | c <- myBorderless]
    , [className =? c --> doIgnore         | c <- myIgnores]
    , [className =? c --> doFloat          | c <- myFloats]
    , [isFullscreen   --> doFullFloat]
    , [manageHook defaultConfig]
    ]) where
      myIgnores = ["conky"]
      myFloats = ["Gimp", "Guake"]
      myBorderless = ["Guake", "Termite"]

xmonadModKey = mod1Mask

myKeys =
    [ (( xmonadModKey, xK_Return ), spawn "~/.util/program_menu")
    , (( xmonadModKey, xK_Tab ), spawn "~/.util/window_menu")
    , (( xmonadModKey, xK_backslash ), spawn "~/.util/host_menu")
    , (( xmonadModKey .|. shiftMask, xK_l ), spawn "~/.util/lock")
    , (( xmonadModKey, xK_o), spawn "nextbg.py")
    , (( xmonadModKey, xK_p), spawn "nextbg.py --prev")
    , (( xmonadModKey .|. shiftMask, xK_p), spawn "~/.util/macro")
    , (( xmonadModKey, xK_i), windows W.swapMaster)
    , (( xmonadModKey .|. shiftMask, xK_m), spawn "~/.util/enable_touchpad")
    , (( xmonadModKey .|. shiftMask, xK_n), spawn "~/.util/disable_touchpad")
    , (( xmonadModKey, xK_b), sendMessage ToggleStruts)
    , (( xmonadModKey .|. shiftMask, xK_b), withFocused toggleBorder)
    , (( xmonadModKey .|. shiftMask, xK_a), spawn "~/.util/monitor-setup-1")
    , (( xmonadModKey .|. shiftMask, xK_s), spawn "~/.util/monitor-setup-2")
    , (( xmonadModKey .|. shiftMask, xK_d), spawn "~/.util/monitor-setup-3")
    , (( xmonadModKey .|. shiftMask, xK_f), spawn "~/.util/monitor-setup-4")
    , (( xmonadModKey .|. shiftMask, xK_r), spawn "~/bin/tcolor -R")
    ] ++ [((m .|. xmonadModKey, k), windows $ f i) -- Replace 'xmonadModKey' with your mod key of choice.
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
    ] ++ [((m .|. xmonadModKey .|. controlMask, k), windows $ f i) -- Replace 'xmonadModKey' with your mod key of choice.
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
    ]


myLogHook :: D.Client -> PP
myLogHook dbus = def {ppOutput = dbusOutput dbus}

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

main = do
   spawn "~/.dotfiles/xinit/twm-common"
   spawn "~/.dotfiles/xinit/xmonad"
   dbus <- D.connectSession
   D.requestName dbus (D.busName_ "org.xmonad.Log")
      [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
   xmonad $ ewmh $ withUrgencyHook NoUrgencyHook $ defaultConfig
      { startupHook = setWMName "LG3D"
      , borderWidth = 2
      , normalBorderColor = "#000000"
      , focusedBorderColor = "#b5b3aa"
      , focusFollowsMouse = False
      , workspaces = myWorkspaces
      , layoutHook = smartBorders $ myLayout
      , manageHook = myManageHook
      , handleEventHook = docksEventHook
      , logHook = dynamicLogWithPP (myLogHook dbus)
      , terminal = "~/.util/terminal"
      , modMask = xmonadModKey
      }

      `additionalKeys` myKeys
