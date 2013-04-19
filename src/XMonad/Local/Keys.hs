--------------------------------------------------------------------------------
-- | Key bindings.
module XMonad.Local.Keys (keys, rawKeys) where

--------------------------------------------------------------------------------
-- General Haskell Packages.
import qualified Data.Map as M
import Graphics.X11.Xlib
import System.Exit (ExitCode(..), exitWith)

--------------------------------------------------------------------------------
-- Package: xmonad.
import XMonad.Core hiding (keys)
import XMonad.Layout
import XMonad.Operations
import qualified XMonad.StackSet as W

--------------------------------------------------------------------------------
-- Package: xmonad-contrib.
import XMonad.Actions.OnScreen (onlyOnScreen)
import XMonad.Actions.PhysicalScreens (onNextNeighbour)
import XMonad.Actions.Promote (promote)
import XMonad.Hooks.ManageDocks (ToggleStruts(..))
import XMonad.Layout.BoringWindows (markBoring)
import XMonad.Layout.ResizableTile
import XMonad.Layout.ToggleLayouts (ToggleLayout(..))
import XMonad.Prompt.Shell (shellPrompt)
import XMonad.Prompt.Window (windowPromptGoto)
import XMonad.Prompt.XMonad (xmonadPrompt)
import XMonad.Util.EZConfig (mkKeymap)
import XMonad.Util.Paste (sendKey)

--------------------------------------------------------------------------------
-- Local modules.
import qualified XMonad.Local.Prompt as Local
import XMonad.Local.Workspaces (asKey, viewPrevWS)

--------------------------------------------------------------------------------
-- Join all the key maps into a single list and send it through @mkKeymap@.
keys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
keys c = mkKeymap c (rawKeys c)

--------------------------------------------------------------------------------
-- | Access the unprocessed key meant to be fed into @mkKeymap@.
rawKeys :: XConfig Layout -> [(String, X ())]
rawKeys c = concatMap ($ c) keymaps where
  keymaps = [ baseKeys
            , windowKeys
            , workspaceKeys
            , layoutKeys
            , screenKeys
            , appKeys
            , musicKeys
            ]

--------------------------------------------------------------------------------
-- Specifically manage my prefix key (C-z), and for controlling XMonad.
--
-- TODO: spawn "xmonad --recompile && xmonad --restart"
-- TODO: ("C-z C-z", return ()) -- FIXME: replace with jumpToPrevWS
baseKeys :: XConfig Layout -> [(String, X ())]
baseKeys _ =
  [ ("C-z z",   sendKey controlMask xK_z) -- Send C-z to application.
  , ("C-z C-g", return ()) -- No-op to cancel the prefix key.
  , ("C-z g",   return ()) -- Same as above.
  , ("C-z S-q", io $ exitWith ExitSuccess)
  , ("C-z x",   xmonadPrompt Local.promptConfig)
  ]

--------------------------------------------------------------------------------
-- Window focusing, swapping, and other actions.
windowKeys :: XConfig Layout -> [(String, X ())]
windowKeys _ =
  [ ("C-z n",   windows W.focusDown)
  , ("C-z p",   windows W.focusUp)
  , ("C-z o",   windows W.focusDown)
  , ("C-z S-n", windows W.swapDown)
  , ("C-z S-p", windows W.swapUp)
  , ("C-z m",   windows W.focusMaster)
  , ("C-z S-m", promote) -- Promote current window to master.
  , ("C-z S-t", withFocused $ windows . W.sink) -- Tile window.
  , ("C-z b",   markBoring)
  , ("C-z w",   windowPromptGoto Local.promptConfig)
  , ("C-z S-k", kill) -- Kill the current window.
  , ("M-<L>",   sendMessage Shrink)
  , ("M-<R>",   sendMessage Expand)
  , ("M-<U>",   sendMessage MirrorShrink)
  , ("M-<D>",   sendMessage MirrorExpand)
  , ("M--",     sendMessage $ IncMasterN (-1))
  , ("M-=",     sendMessage $ IncMasterN 1)
  ]

--------------------------------------------------------------------------------
-- Keys for manipulating workspaces.
workspaceKeys :: XConfig Layout -> [(String, X ())]
workspaceKeys c = workspaceMovementKeys c ++ workspaceOtherKeys c

--------------------------------------------------------------------------------
-- Keys for moving windows between workspaces and switching workspaces.
workspaceMovementKeys :: XConfig Layout -> [(String, X ())]
workspaceMovementKeys c = do
  (name,   key)    <- zip (workspaces c) (map asKey $ workspaces c)
  (prefix, action) <- actions
  return (prefix ++ key, windows $ action name)
  where actions = [ -- Bring workspace N to the current screen.
                    ("C-z ",   W.greedyView)
                  , -- Move the current window to workspace N.
                    ("C-z S-", W.shift)
                  , -- Force workspace N to the second screen.
                    ("C-z C-", onlyOnScreen 1)
                  ]

--------------------------------------------------------------------------------
-- Other operations on workspaces not covered in 'workspaceMovementKeys'.
workspaceOtherKeys :: XConfig Layout -> [(String, X ())]
workspaceOtherKeys _ =
  [ ("C-z l",   viewPrevWS)
  , ("C-z C-z", viewPrevWS) -- TODO: Remove duplicate binding.
  ]

--------------------------------------------------------------------------------
-- Layout switching and manipulation.
layoutKeys :: XConfig Layout -> [(String, X ())]
layoutKeys c =
  [ ("C-z <Space>",   sendMessage ToggleLayout)
  , ("C-z C-<Space>", sendMessage NextLayout)
  , ("C-z S-<Space>", setLayout $ layoutHook c)
  , ("C-z s",         sendMessage ToggleStruts)
  ]

--------------------------------------------------------------------------------
-- Keys to manipulate screens (actual physical monitors).
screenKeys :: XConfig Layout -> [(String, X ())]
screenKeys _ =
  [ ("C-z C-o", onNextNeighbour W.view)
  ]

--------------------------------------------------------------------------------
-- Keys for launching applications.
appKeys :: XConfig Layout -> [(String, X ())]
appKeys c =
  [ ("C-z t",     spawn $ terminal c)
  , ("C-z C-t",   spawn "urxvtc -name BigTerm")
  , ("M-l",       spawn "xscreensaver-command -lock")
  , ("<Print>",   spawn "screenshot.sh root")
  , ("M-<Print>", spawn "screenshot.sh window")
  , ("M-<Space>", shellPrompt Local.promptConfig)

    -- Laptops and keyboards with media/meta keys.
  , ("<XF86WebCam>",         spawn "tptoggle.sh") -- Weird.
  , ("<XF86TouchpadToggle>", spawn "tptoggle.sh")
  ]

--------------------------------------------------------------------------------
-- Keys for controlling music and volume.
musicKeys :: XConfig Layout -> [(String, X ())]
musicKeys _ =
  [ ("M-<F1>",  spawn "mpc-pause")
  , ("M-<F2>",  spawn "mpc prev")
  , ("M-<F3>",  spawn "mpc next")
  , ("M4-<F1>", spawn "amixer set Master toggle")
  , ("M4-<F2>", spawn "amixer set Master 5%-")
  , ("M4-<F3>", spawn "amixer set Master 5%+")

    -- Keys for my laptop and keyboards with media keys.
  , ("M-<XF86AudioMute>",        spawn "mpc-pause")
  , ("M-<XF86AudioLowerVolume>", spawn "mpc prev")
  , ("M-<XF86AudioRaiseVolume>", spawn "mpc next")
  , ("<XF86AudioMute>",          spawn "amixer set Master toggle")
  , ("<XF86AudioLowerVolume>",   spawn "amixer set Master 5%-")
  , ("<XF86AudioRaiseVolume>",   spawn "amixer set Master 5%+")
  ]