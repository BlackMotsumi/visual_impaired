
/// ============================================================
/// VOICE COMMAND
/// ============================================================
///
/// All commands currently used by Vision Guide.
///
/// IMPORTANT:
/// Do not remove commands from this enum without checking
/// dashboard_screen.dart and activity screens first.
/// ============================================================
library;

enum VoiceCommand {
  // ------------------------------------------------------------
  // GENERAL
  // ------------------------------------------------------------

  noInput,
  unknown,

  help,
  repeat,
  back,
  home,
  cancel,

  // ------------------------------------------------------------
  // AUTHENTICATION
  // ------------------------------------------------------------

  login,
  register,
  logout,

  // ------------------------------------------------------------
  // DASHBOARD
  // ------------------------------------------------------------

  accessibility,
  studyGroups,
  navigation,

  navigateBuildings,
  campusInfo,
  offlineMaps,
  emergency,
  feedback,

  profile,
  settings,
}

/// ============================================================
/// COMMAND PROCESSOR
/// ============================================================
///
/// Converts speech-to-text results into a VoiceCommand.
///
/// Example:
///
/// "Please open the study groups"
///        -> VoiceCommand.studyGroups
///
/// "Take me back to dashboard"
///        -> VoiceCommand.home
///
/// "I need emergency help"
///        -> VoiceCommand.emergency
/// ============================================================

class CommandProcessor {
  // ------------------------------------------------------------
  // PROCESS
  // ------------------------------------------------------------

  static VoiceCommand process(String speech) {
    final String command = _normalize(speech);

    print(
      'COMMAND PROCESSOR INPUT: "$command"',
    );

    // ----------------------------------------------------------
    // EMPTY INPUT
    // ----------------------------------------------------------

    if (command.isEmpty) {
      return VoiceCommand.noInput;
    }

    // ----------------------------------------------------------
    // HOME / DASHBOARD
    // ----------------------------------------------------------
    //
    // Check this BEFORE generic "back".
    //
    // This is important because:
    //
    // "go back to dashboard"
    //
    // should mean:
    //
    // VoiceCommand.home
    //
    // rather than:
    //
    // VoiceCommand.back
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'home',
      'go home',
      'take me home',
      'dashboard',
      'open dashboard',
      'go to dashboard',
      'go back to dashboard',
      'take me back to dashboard',
      'return to dashboard',
      'return back to dashboard',
      'back to dashboard',
      'go back home',
      'return home',
    ])) {
      return VoiceCommand.home;
    }

    // ----------------------------------------------------------
    // BUILDING NAVIGATION
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'navigate buildings',
      'navigate building',
      'building navigation',
      'building directions',
      'find building',
      'find a building',
      'find the building',
      'navigate to building',
      'navigate to a building',
      'navigate to the building',
      'campus navigation',
      'navigate campus',
      'find my building',
      'directions to building',
      'directions to a building',
    ])) {
      return VoiceCommand.navigateBuildings;
    }

    // ----------------------------------------------------------
    // OFFLINE MAPS
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'offline maps',
      'offline map',
      'open offline maps',
      'open offline map',
      'use offline maps',
      'use offline map',
      'offline navigation',
      'offline directions',
    ])) {
      return VoiceCommand.offlineMaps;
    }

    // ----------------------------------------------------------
    // CAMPUS INFORMATION
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'campus information',
      'campus info',
      'campus information please',
      'tell me about campus',
      'information about campus',
      'about campus',
      'campus details',
      'tell me campus information',
      'give me campus information',
    ])) {
      return VoiceCommand.campusInfo;
    }

    // ----------------------------------------------------------
    // EMERGENCY
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'emergency',
      'emergency help',
      'help me emergency',
      'i need emergency help',
      'call emergency',
      'emergency assistance',
      'i need emergency assistance',
      'this is an emergency',
      'help emergency',
    ])) {
      return VoiceCommand.emergency;
    }

    // ----------------------------------------------------------
    // STUDY GROUPS
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'study groups',
      'study group',
      'open study groups',
      'open study group',
      'go to study groups',
      'go to study group',
      'study group activity',
      'study groups activity',
      'study',
    ])) {
      return VoiceCommand.studyGroups;
    }

    // ----------------------------------------------------------
    // ACCESSIBILITY
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'accessibility',
      'accessibility settings',
      'open accessibility',
      'open accessibility settings',
      'go to accessibility',
      'go to accessibility settings',
      'accessibility options',
      'accessibility activity',
    ])) {
      return VoiceCommand.accessibility;
    }

    // ----------------------------------------------------------
    // GENERAL NAVIGATION
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'navigation',
      'navigate',
      'open navigation',
      'start navigation',
      'go to navigation',
      'navigation screen',
      'open navigation screen',
      'map',
      'maps',
      'open map',
      'open maps',
    ])) {
      return VoiceCommand.navigation;
    }

    // ----------------------------------------------------------
    // FEEDBACK
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'feedback',
      'give feedback',
      'send feedback',
      'open feedback',
      'provide feedback',
      'feedback activity',
      'feedback screen',
      'give me feedback',
    ])) {
      return VoiceCommand.feedback;
    }

    // ----------------------------------------------------------
    // PROFILE
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'profile',
      'my profile',
      'open profile',
      'go to profile',
      'profile settings',
      'open my profile',
    ])) {
      return VoiceCommand.profile;
    }

    // ----------------------------------------------------------
    // SETTINGS
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'settings',
      'open settings',
      'go to settings',
      'application settings',
      'app settings',
      'open application settings',
    ])) {
      return VoiceCommand.settings;
    }

    // ----------------------------------------------------------
    // HELP
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'help',
      'what can i say',
      'what can i do',
      'commands',
      'available commands',
      'show commands',
      'list commands',
      'what commands can i use',
      'how can you help me',
      'help me',
    ])) {
      return VoiceCommand.help;
    }

    // ----------------------------------------------------------
    // REPEAT
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'repeat',
      'repeat that',
      'say that again',
      'repeat please',
      'repeat the message',
      'please repeat',
      'can you repeat',
      'say it again',
      'repeat what you said',
    ])) {
      return VoiceCommand.repeat;
    }

    // ----------------------------------------------------------
    // BACK
    // ----------------------------------------------------------
    //
    // Generic back commands.
    //
    // Dashboard-specific phrases such as
    // "go back to dashboard" were handled above as HOME.
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'back',
      'go back',
      'take me back',
      'return',
      'return back',
      'previous screen',
      'go to previous screen',
      'previous page',
      'go back one screen',
    ])) {
      return VoiceCommand.back;
    }

    // ----------------------------------------------------------
    // CANCEL
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'cancel',
      'cancel that',
      'stop',
      'stop that',
      'never mind',
      'nevermind',
      'cancel command',
    ])) {
      return VoiceCommand.cancel;
    }

    // ----------------------------------------------------------
    // LOGIN
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'login',
      'log in',
      'sign in',
      'signin',
      'please login',
      'please log in',
      'i want to login',
      'i want to log in',
    ])) {
      return VoiceCommand.login;
    }

    // ----------------------------------------------------------
    // REGISTER
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'register',
      'sign up',
      'signup',
      'create account',
      'create an account',
      'new account',
      'create my account',
      'i want to register',
      'i want to sign up',
    ])) {
      return VoiceCommand.register;
    }

    // ----------------------------------------------------------
    // LOGOUT
    // ----------------------------------------------------------

    if (_matchesAny(command, [
      'logout',
      'log out',
      'sign out',
      'signout',
      'please logout',
      'please log out',
      'i want to logout',
      'i want to log out',
    ])) {
      return VoiceCommand.logout;
    }

    // ----------------------------------------------------------
    // UNKNOWN
    // ----------------------------------------------------------

    print(
      'COMMAND PROCESSOR: Unknown command "$command"',
    );

    return VoiceCommand.unknown;
  }

  // ------------------------------------------------------------
  // NORMALIZE
  // ------------------------------------------------------------

  static String _normalize(String value) {
    String result = value.toLowerCase().trim();

    // Remove punctuation.
    result = result.replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    // Replace multiple spaces with one space.
    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result.trim();
  }

  // ------------------------------------------------------------
  // MATCH
  // ------------------------------------------------------------

  static bool _matchesAny(
    String value,
    List<String> commands,
  ) {
    for (final String command in commands) {
      // Exact match.
      if (value == command) {
        return true;
      }

      // Natural spoken sentence containing the command.
      if (value.contains(command)) {
        return true;
      }
    }

    return false;
  }
}

