import XMonad

import XMonad.Actions.NoBorders
import XMonad.Actions.PhysicalScreens

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook

import XMonad.Layout.Dishes
import XMonad.Layout.Grid
import XMonad.Layout.LayoutHints
import XMonad.Layout.NoBorders
import XMonad.Layout.Reflect
import XMonad.Layout.Spacing
import XMonad.Layout.Spiral
import XMonad.Layout.ThreeColumns

import XMonad.Util.EZConfig
import XMonad.Util.Run

import qualified Codec.Binary.UTF8.String as UTF8
import qualified Data.Map        as M
import qualified Data.Set        as S
import qualified XMonad.StackSet as W

import Control.Concurrent
import System.IO

import Data.List

-- Define workspaces
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

-- Define layout
myLayout = avoidStruts(tiled ||| reverse_tiled ||| threecol ||| Grid ||| Full)
   where
      tiled = Tall nmaster delta ratio
      threecol = ThreeColMid nmaster delta ratio
      reverse_tiled = reflectHoriz $ tiled
      nmaster = 1
      delta = 5/100
      ratio = 1/2

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
      myBorderless = ["Guake"]

xmonadModKey = mod1Mask

main = do
   spawn "~/.dotfiles/xinit/twm-common"
   spawn "~/.dotfiles/xinit/xmonad"
   xmonad $ ewmh $ defaultConfig
      { startupHook = setWMName "LG3D"
      , borderWidth = 2
      , normalBorderColor = "#001535"
      , focusedBorderColor = "#ffffff"
      , focusFollowsMouse = False
      , workspaces = myWorkspaces
      , layoutHook = smartBorders $ myLayout
      , manageHook = myManageHook
      , handleEventHook = ewmhDesktopsEventHook <+> docksEventHook
      , logHook = ewmhDesktopsLogHook
      , terminal = "~/.util/terminal"
      , modMask = xmonadModKey
      }

      `additionalKeys` myKeys

myKeys =
    [ (( xmonadModKey, xK_Return ), spawn "~/.util/program_menu")
    , (( xmonadModKey, xK_Tab ), spawn "~/.util/window_menu")
    , (( xmonadModKey, xK_backslash ), spawn "~/.util/host_menu")
    , (( xmonadModKey .|. shiftMask, xK_l ), spawn "~/.util/lock")
    , (( xmonadModKey, xK_o), spawn "nextbg.py")
    , (( xmonadModKey, xK_p), spawn "nextbg.py --prev")
    , (( xmonadModKey .|. shiftMask, xK_o), spawn "~/.util/browser")
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
    , (( xmonadModKey .|. shiftMask, xK_BackSpace ), spawn "amixer set Capture toggle")
    ] ++ [((m .|. xmonadModKey, k), windows $ f i) -- Replace 'xmonadModKey' with your mod key of choice.
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
    ] ++ [((m .|. xmonadModKey .|. controlMask, k), windows $ f i) -- Replace 'xmonadModKey' with your mod key of choice.
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
    ] ++ [((m .|. xmonadModKey, k), f sc)
         | (k, sc) <- zip [xK_w, xK_e, xK_r] [0..]
         , (f, m) <- [(viewScreen def, 0), (sendToScreen def, shiftMask)]
    ]
