import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:visual_impaired/theme/app_theme.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterTts _tts = FlutterTts();

  final stt.SpeechToText _speech = stt.SpeechToText();

  // ============================================================
  // STATE
  // ============================================================

  bool _isSpeaking = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _voiceLoopStarted = false;
  bool _isExiting = false;

  String _searchText = '';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _currentGroups = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeVoice();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcome();
    });
  }

  // ============================================================
  // INITIALIZE VOICE
  // ============================================================

  Future<void> _initializeVoice() async {
    try {
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = true;
        });
      });

      _tts.setCompletionHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      _tts.setCancelHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      _tts.setErrorHandler((message) {
        debugPrint('STUDY GROUP TTS ERROR: $message');

        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      final bool available = await _speech.initialize(
        onStatus: (String status) {
          debugPrint('STUDY GROUP SPEECH STATUS: $status');

          if (!mounted) return;

          setState(() {
            _isListening = status == 'listening';
          });
        },
        onError: (dynamic error) {
          debugPrint('STUDY GROUP SPEECH ERROR: $error');

          if (!mounted) return;

          setState(() {
            _isListening = false;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });

      if (!available) {
        await _speak(
          'Voice control is not available on this device. '
          'Please check your microphone and speech recognition settings.',
        );
      }
    } catch (e) {
      debugPrint('STUDY GROUP VOICE INITIALIZATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Future<void> _welcome() async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted || _isExiting) return;

    await _speak(
      'Welcome to Study Groups. '
      'This page is fully voice controlled. '
      'You can say list study groups, '
      'search for a subject or course, '
      'tell me about a study group, '
      'join a study group, '
      'leave a study group, '
      'or say go back to dashboard. '
      'When you are ready, please speak your command.',
    );

    if (!mounted || _isExiting) return;

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    _startVoiceLoop();
  }

  // ============================================================
  // SPEAK
  // ============================================================

  Future<void> _speak(String message) async {
    if (message.trim().isEmpty) {
      return;
    }

    try {
      await _tts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });

      await _tts.speak(message);
    } catch (e) {
      debugPrint('STUDY GROUP SPEAK ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    }
  }

  // ============================================================
  // VOICE LOOP
  // ============================================================

  void _startVoiceLoop() {
    if (_voiceLoopStarted ||
        !_speechAvailable ||
        _isExiting ||
        !mounted) {
      return;
    }

    _voiceLoopStarted = true;

    _runVoiceLoop();
  }

  Future<void> _runVoiceLoop() async {
    while (mounted && !_isExiting) {
      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted || _isExiting) {
        break;
      }

      final String? command = await _listenOnce();

      if (!mounted || _isExiting) {
        break;
      }

      if (command == null || command.trim().isEmpty) {
        continue;
      }

      await _processVoiceCommand(command);
    }

    _voiceLoopStarted = false;
  }

  // ============================================================
  // LISTEN ONCE
  // ============================================================

  Future<String?> _listenOnce() async {
    if (!_speechAvailable || _isExiting || !mounted) {
      return null;
    }

    try {
      await _tts.stop();

      final Completer<String?> completer = Completer<String?>();

      bool resultReceived = false;

      if (mounted) {
        setState(() {
          _isListening = true;
          _isSpeaking = false;
        });
      }

      await _speech.listen(
        localeId: 'en_ZA',
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        partialResults: false,
        cancelOnError: true,
        onResult: (result) {
          if (result.finalResult && !resultReceived) {
            resultReceived = true;

            final String text = result.recognizedWords.trim();

            if (!completer.isCompleted) {
              completer.complete(
                text.isEmpty ? null : text,
              );
            }
          }
        },
      );

      final String? result = await completer.future.timeout(
        const Duration(seconds: 23),
        onTimeout: () {
          return null;
        },
      );

      await _speech.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      return result;
    } catch (e) {
      debugPrint('STUDY GROUP LISTEN ERROR: $e');

      try {
        await _speech.stop();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      return null;
    }
  }

  // ============================================================
  // NORMALIZE VOICE COMMAND
  // ============================================================

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  // ============================================================
  // PROCESS VOICE COMMAND
  // ============================================================

  Future<void> _processVoiceCommand(String command) async {
    final String normalized = _normalize(command);

    debugPrint(
      'STUDY GROUP VOICE COMMAND: $normalized',
    );

    if (normalized.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // GO BACK
    // ----------------------------------------------------------

    if (_isBackCommand(normalized)) {
      await _goBackToDashboard();
      return;
    }

    // ----------------------------------------------------------
    // YES / NO
    // ----------------------------------------------------------

    if (_isYesCommand(normalized)) {
      await _goBackToDashboard();
      return;
    }

    if (_isNoCommand(normalized)) {
      await _speak(
        'Okay. I will keep you on the Study Groups page. '
        'You can say list study groups, '
        'search for a group, '
        'tell me about a group, '
        'join a group, '
        'leave a group, '
        'or say go back to dashboard.',
      );

      return;
    }

    // ----------------------------------------------------------
    // STOP
    // ----------------------------------------------------------

    if (_isStopCommand(normalized)) {
      await _tts.stop();

      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // HELP
    // ----------------------------------------------------------

    if (_isHelpCommand(normalized)) {
      await _speak(
        'You can use the following voice commands. '
        'Say list study groups to hear available groups. '
        'Say search followed by a subject, course, location or group name. '
        'Say tell me about followed by a group name. '
        'Say join followed by a group name to join. '
        'Say leave followed by a group name to leave. '
        'Say go back to dashboard when you are finished.',
      );

      return;
    }

    // ----------------------------------------------------------
    // LIST GROUPS
    // ----------------------------------------------------------

    if (_isListCommand(normalized)) {
      await _listStudyGroups();
      return;
    }

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    if (_isSearchCommand(normalized)) {
      final String searchTerm = _extractSearchTerm(normalized);

      if (searchTerm.isEmpty) {
        await _speak(
          'Please say search followed by a subject, '
          'course, location or study group name.',
        );

        return;
      }

      await _searchGroups(searchTerm);

      return;
    }

    // ----------------------------------------------------------
    // JOIN
    // ----------------------------------------------------------

    if (_isJoinCommand(normalized)) {
      final String groupName = _extractAfterCommand(
        normalized,
        [
          'join study group',
          'join the study group',
          'join group',
          'join the group',
          'join',
        ],
      );

      if (groupName.isEmpty) {
        await _speak(
          'Please say join followed by the study group name.',
        );

        return;
      }

      await _joinGroupByVoice(groupName);

      return;
    }

    // ----------------------------------------------------------
    // LEAVE
    // ----------------------------------------------------------

    if (_isLeaveCommand(normalized)) {
      final String groupName = _extractAfterCommand(
        normalized,
        [
          'leave study group',
          'leave the study group',
          'leave group',
          'leave the group',
          'leave',
        ],
      );

      if (groupName.isEmpty) {
        await _speak(
          'Please say leave followed by the study group name.',
        );

        return;
      }

      await _leaveGroupByVoice(groupName);

      return;
    }

    // ----------------------------------------------------------
    // DETAILS
    // ----------------------------------------------------------

    if (_isDetailsCommand(normalized)) {
      final String groupName = _extractAfterCommand(
        normalized,
        [
          'tell me about the study group',
          'tell me about study group',
          'information about the study group',
          'information about study group',
          'details about the study group',
          'details about study group',
          'tell me about the group',
          'tell me about group',
          'information about the group',
          'information about group',
          'details about the group',
          'details about group',
          'what is the study group',
          'what is study group',
          'what is the group',
          'tell me about',
        ],
      );

      if (groupName.isEmpty) {
        await _speak(
          'Please say tell me about followed by the study group name.',
        );

        return;
      }

      await _showGroupDetailsByVoice(groupName);

      return;
    }

    // ----------------------------------------------------------
    // DIRECT GROUP NAME
    // ----------------------------------------------------------

    final QueryDocumentSnapshot<Map<String, dynamic>>? directGroup =
        _findGroup(normalized);

    if (directGroup != null) {
      await _showGroupDetailsByVoice(
        (directGroup.data()['name'] ?? 'study group').toString(),
      );

      return;
    }

    // ----------------------------------------------------------
    // UNKNOWN COMMAND
    // ----------------------------------------------------------

    await _speak(
      'I did not understand that command. '
      'You can say list study groups, '
      'search followed by a subject or course, '
      'tell me about a study group, '
      'join a study group, '
      'leave a study group, '
      'help, '
      'or go back to dashboard.',
    );
  }

  // ============================================================
  // COMMAND CHECKS
  // ============================================================

  bool _isBackCommand(String text) {
    const commands = [
      'back',
      'go back',
      'go back to dashboard',
      'return',
      'return to dashboard',
      'dashboard',
      'go to dashboard',
      'take me back',
      'take me to dashboard',
      'exit',
      'close study groups',
      'close study group',
    ];

    return commands.contains(text);
  }

  bool _isYesCommand(String text) {
    const commands = [
      'yes',
      'yes please',
      'yes go back',
      'yes return',
      'yes dashboard',
      'go ahead',
    ];

    return commands.contains(text);
  }

  bool _isNoCommand(String text) {
    const commands = [
      'no',
      'no thank you',
      'no thanks',
      'stay here',
      'stay',
      'not yet',
    ];

    return commands.contains(text);
  }

  bool _isStopCommand(String text) {
    const commands = [
      'stop',
      'stop speaking',
      'quiet',
      'be quiet',
      'cancel speech',
    ];

    return commands.contains(text);
  }

  bool _isHelpCommand(String text) {
    const commands = [
      'help',
      'please help',
      'i need help',
      'what can i say',
      'what can i do',
      'commands',
      'voice commands',
    ];

    return commands.contains(text);
  }

  bool _isListCommand(String text) {
    const commands = [
      'list',
      'list groups',
      'list study groups',
      'show groups',
      'show study groups',
      'available groups',
      'available study groups',
      'what study groups are available',
      'what groups are available',
      'which study groups are available',
      'which groups are available',
      'study groups',
    ];

    return commands.contains(text);
  }

  bool _isSearchCommand(String text) {
    return text.startsWith('search ') ||
        text.startsWith('find ') ||
        text.startsWith('look for ') ||
        text.startsWith('find a group ') ||
        text.startsWith('search for ');
  }

  bool _isJoinCommand(String text) {
    return text == 'join' ||
        text.startsWith('join ') ||
        text.startsWith('join study group ') ||
        text.startsWith('join the study group ');
  }

  bool _isLeaveCommand(String text) {
    return text == 'leave' ||
        text.startsWith('leave ') ||
        text.startsWith('leave study group ') ||
        text.startsWith('leave the study group ');
  }

  bool _isDetailsCommand(String text) {
    return text.startsWith('tell me about') ||
        text.startsWith('information about') ||
        text.startsWith('details about') ||
        text.startsWith('what is the study group') ||
        text.startsWith('what is study group') ||
        text.startsWith('what is the group');
  }

  // ============================================================
  // EXTRACT SEARCH TERM
  // ============================================================

  String _extractSearchTerm(String command) {
    const prefixes = [
      'search for ',
      'search ',
      'find a group ',
      'find ',
      'look for ',
    ];

    for (final String prefix in prefixes) {
      if (command.startsWith(prefix)) {
        return command.substring(prefix.length).trim();
      }
    }

    return '';
  }

  // ============================================================
  // EXTRACT COMMAND VALUE
  // ============================================================

  String _extractAfterCommand(
    String command,
    List<String> prefixes,
  ) {
    for (final String prefix in prefixes) {
      if (command.startsWith(prefix)) {
        return command.substring(prefix.length).trim();
      }
    }

    return '';
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get _currentUser => _auth.currentUser;

  // ============================================================
  // GET GROUPS
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getGroups() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('study_groups')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .get();

      if (mounted) {
        setState(() {
          _currentGroups = snapshot.docs;
        });
      }

      return snapshot.docs;
    } catch (e) {
      debugPrint('GET STUDY GROUPS ERROR: $e');

      return [];
    }
  }

  // ============================================================
  // FIND GROUP
  // ============================================================

  QueryDocumentSnapshot<Map<String, dynamic>>? _findGroup(
    String searchText,
  ) {
    final String search = _normalize(searchText);

    if (search.isEmpty) {
      return null;
    }

    // Exact match.

    for (final document in _currentGroups) {
      final Map<String, dynamic> data = document.data();

      final String name = _normalize(
        (data['name'] ?? '').toString(),
      );

      if (name == search) {
        return document;
      }
    }

    // Contains match.

    for (final document in _currentGroups) {
      final Map<String, dynamic> data = document.data();

      final String name = _normalize(
        (data['name'] ?? '').toString(),
      );

      if (name.contains(search) || search.contains(name)) {
        return document;
      }
    }

    // Search other fields.

    for (final document in _currentGroups) {
      final Map<String, dynamic> data = document.data();

      final String subject = _normalize(
        (data['subject'] ?? '').toString(),
      );

      final String course = _normalize(
        (data['course'] ?? '').toString(),
      );

      final String location = _normalize(
        (data['location'] ?? '').toString(),
      );

      if (subject.contains(search) ||
          course.contains(search) ||
          location.contains(search)) {
        return document;
      }
    }

    return null;
  }

  // ============================================================
  // LIST STUDY GROUPS
  // ============================================================

  Future<void> _listStudyGroups() async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups =
        await _getGroups();

    if (groups.isEmpty) {
      await _speak(
        'There are currently no study groups available. '
        'You can say search followed by a subject or course. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );

      return;
    }

    final StringBuffer message = StringBuffer();

    message.write(
      'There are ${groups.length} study groups available. ',
    );

    final int limit = groups.length > 10 ? 10 : groups.length;

    for (int i = 0; i < limit; i++) {
      final Map<String, dynamic> data = groups[i].data();

      final String name =
          (data['name'] ?? 'Unnamed study group').toString();

      final String subject =
          (data['subject'] ?? 'subject not specified').toString();

      message.write(
        '${i + 1}. $name, $subject. ',
      );
    }

    if (groups.length > 10) {
      message.write(
        'There are more groups available. '
        'You can say search followed by a subject, course, '
        'or group name to find another group. ',
      );
    }

    message.write(
      'Would you like to go back to dashboard? '
      'Say yes or say go back. '
      'If you want to continue, say no.',
    );

    await _speak(message.toString());
  }

  // ============================================================
  // SEARCH GROUPS
  // ============================================================

  Future<void> _searchGroups(String searchTerm) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups =
        await _getGroups();

    final String search = _normalize(searchTerm);

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> matches =
        groups.where((document) {
      final Map<String, dynamic> data = document.data();

      final String name =
          _normalize((data['name'] ?? '').toString());

      final String subject =
          _normalize((data['subject'] ?? '').toString());

      final String course =
          _normalize((data['course'] ?? '').toString());

      final String location =
          _normalize((data['location'] ?? '').toString());

      return name.contains(search) ||
          subject.contains(search) ||
          course.contains(search) ||
          location.contains(search);
    }).toList();

    if (mounted) {
      setState(() {
        _searchText = searchTerm;
      });
    }

    if (matches.isEmpty) {
      await _speak(
        'I could not find any study groups matching '
        '$searchTerm. '
        'You can try another search or say list study groups. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );

      return;
    }

    final StringBuffer message = StringBuffer();

    message.write(
      'I found ${matches.length} study group',
    );

    if (matches.length != 1) {
      message.write('s');
    }

    message.write(
      ' matching $searchTerm. ',
    );

    final int limit = matches.length > 8 ? 8 : matches.length;

    for (int i = 0; i < limit; i++) {
      final Map<String, dynamic> data = matches[i].data();

      final String name =
          (data['name'] ?? 'Unnamed study group').toString();

      final String subject =
          (data['subject'] ?? 'subject not specified').toString();

      final String course =
          (data['course'] ?? 'course not specified').toString();

      message.write(
        '${i + 1}. $name. '
        '$subject. '
        '$course. ',
      );
    }

    message.write(
      'To hear more about a group, say '
      'tell me about followed by the group name. '
      'Would you like to go back to dashboard? '
      'Say yes or say go back.',
    );

    await _speak(message.toString());
  }

  // ============================================================
  // SHOW GROUP DETAILS BY VOICE
  // ============================================================

  Future<void> _showGroupDetailsByVoice(
    String groupName,
  ) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups =
        await _getGroups();

    QueryDocumentSnapshot<Map<String, dynamic>>? group;

    final String search = _normalize(groupName);

    // Exact match first.

    for (final document in groups) {
      final String name = _normalize(
        (document.data()['name'] ?? '').toString(),
      );

      if (name == search) {
        group = document;
        break;
      }
    }

    // Contains match.

    group ??= _findGroup(search);

    if (group == null) {
      await _speak(
        'I could not find a study group called '
        '$groupName. '
        'Say list study groups to hear the available groups, '
        'or say search followed by a subject or course. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );

      return;
    }

    final Map<String, dynamic> data = group.data();

    final String name =
        (data['name'] ?? 'Study Group').toString();

    final String subject =
        (data['subject'] ?? 'Subject not specified').toString();

    final String course =
        (data['course'] ?? 'Course not specified').toString();

    final String description =
        (data['description'] ?? 'No description available.').toString();

    final String location =
        (data['location'] ?? 'Location not specified').toString();

    final String meetingTime =
        (data['meetingTime'] ?? 'Meeting time not specified').toString();

    final int memberCount = _getInt(
      data['memberCount'],
    );

    final int maxMembers = _getInt(
      data['maxMembers'],
    );

    final String membersText = maxMembers > 0
        ? '$memberCount out of $maxMembers members'
        : '$memberCount members';

    final bool isMember = _isMember(data);

    final String membershipText = isMember
        ? 'You are currently a member of this study group.'
        : 'You are not currently a member of this study group.';

    await _speak(
      '$name. '
      'Subject: $subject. '
      'Course: $course. '
      'Description: $description. '
      'Location: $location. '
      'Meeting time: $meetingTime. '
      'Members: $membersText. '
      '$membershipText '
      'You can say join $name to join this group, '
      'or leave $name if you are already a member. '
      'Would you like to go back to dashboard? '
      'Say yes or say go back.',
    );
  }

  // ============================================================
  // JOIN GROUP BY VOICE
  // ============================================================

  Future<void> _joinGroupByVoice(
    String groupName,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      await _speak(
        'You must be logged in before joining a study group. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );

      return;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups =
        await _getGroups();

    final String search = _normalize(groupName);

    QueryDocumentSnapshot<Map<String, dynamic>>? group;

    for (final document in groups) {
      final String name = _normalize(
        (document.data()['name'] ?? '').toString(),
      );

      if (name == search) {
        group = document;
        break;
      }
    }

    group ??= _findGroup(search);

    if (group == null) {
      await _speak(
        'I could not find the study group '
        '$groupName. '
        'Say list study groups to hear the available groups.',
      );

      return;
    }

    final Map<String, dynamic> data = group.data();

    final String actualGroupName =
        (data['name'] ?? groupName).toString();

    final String groupId = group.id;

    await _joinGroup(
      groupId,
      data,
      actualGroupName,
    );
  }

  // ============================================================
  // JOIN GROUP
  // ============================================================

  Future<void> _joinGroup(
    String groupId,
    Map<String, dynamic> group,
    String groupName,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      await _speak(
        'You must be logged in before joining a study group.',
      );

      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> groupReference =
          _firestore.collection('study_groups').doc(groupId);

      final DocumentSnapshot<Map<String, dynamic>> groupSnapshot =
          await groupReference.get();

      if (!groupSnapshot.exists) {
        await _speak(
          'This study group is no longer available. '
          'Would you like to go back to dashboard? '
          'Say yes or say go back.',
        );

        return;
      }

      final Map<String, dynamic> latestData =
          groupSnapshot.data() ?? {};

      final List<dynamic> members = List<dynamic>.from(
        latestData['members'] ?? [],
      );

      final int maxMembers = _getInt(
        latestData['maxMembers'],
      );

      if (members.contains(user.uid)) {
        await _speak(
          'You have already joined $groupName. '
          'Would you like to go back to dashboard? '
          'Say yes or say go back.',
        );

        return;
      }

      if (maxMembers > 0 && members.length >= maxMembers) {
        await _speak(
          '$groupName is already full. '
          'Would you like to go back to dashboard? '
          'Say yes or say go back.',
        );

        return;
      }

      await groupReference.update({
        'members': FieldValue.arrayUnion([
          user.uid,
        ]),
        'memberCount': FieldValue.increment(1),
      });

      await groupReference.collection('members').doc(user.uid).set({
        'userId': user.uid,
        'joinedAt': FieldValue.serverTimestamp(),
        'email': user.email,
        'displayName': user.displayName ?? 'Student',
      });

      await _speak(
        'You have successfully joined $groupName. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back. '
        'If you want to continue using Study Groups, say no.',
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'JOIN STUDY GROUP ERROR: $e',
      );

      await _speak(
        'I could not join $groupName. '
        'Please try again. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );
    }
  }

  // ============================================================
  // LEAVE GROUP BY VOICE
  // ============================================================

  Future<void> _leaveGroupByVoice(
    String groupName,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      await _speak(
        'You are not currently logged in.',
      );

      return;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups =
        await _getGroups();

    final String search = _normalize(groupName);

    QueryDocumentSnapshot<Map<String, dynamic>>? group;

    for (final document in groups) {
      final String name = _normalize(
        (document.data()['name'] ?? '').toString(),
      );

      if (name == search) {
        group = document;
        break;
      }
    }

    group ??= _findGroup(search);

    if (group == null) {
      await _speak(
        'I could not find the study group '
        '$groupName.',
      );

      return;
    }

    final Map<String, dynamic> data = group.data();

    final String actualGroupName =
        (data['name'] ?? groupName).toString();

    await _leaveGroup(
      group.id,
      data,
      actualGroupName,
    );
  }

  // ============================================================
  // LEAVE GROUP
  // ============================================================

  Future<void> _leaveGroup(
    String groupId,
    Map<String, dynamic> group,
    String groupName,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> groupReference =
          _firestore.collection('study_groups').doc(groupId);

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await groupReference.get();

      if (!snapshot.exists) {
        await _speak(
          'The study group is no longer available.',
        );

        return;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? {};

      final List<dynamic> members = List<dynamic>.from(
        data['members'] ?? [],
      );

      if (!members.contains(user.uid)) {
        await _speak(
          'You are not currently a member of $groupName. '
          'Would you like to go back to dashboard? '
          'Say yes or say go back.',
        );

        return;
      }

      await groupReference.update({
        'members': FieldValue.arrayRemove([
          user.uid,
        ]),
        'memberCount': FieldValue.increment(-1),
      });

      await groupReference.collection('members').doc(user.uid).delete();

      await _speak(
        'You have left $groupName. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back. '
        'If you want to continue using Study Groups, say no.',
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'LEAVE STUDY GROUP ERROR: $e',
      );

      await _speak(
        'I could not remove you from $groupName. '
        'Please try again. '
        'Would you like to go back to dashboard? '
        'Say yes or say go back.',
      );
    }
  }

  // ============================================================
  // CHECK MEMBERSHIP
  // ============================================================

  bool _isMember(
    Map<String, dynamic> group,
  ) {
    final User? user = _currentUser;

    if (user == null) {
      return false;
    }

    final List<dynamic> members = List<dynamic>.from(
      group['members'] ?? [],
    );

    return members.contains(user.uid);
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _getInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // GROUP STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _groupsStream() {
    return _firestore
        .collection('study_groups')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // VOICE STATUS CARD
  // ============================================================

  Widget _voiceStatusCard() {
    final bool listening = _isListening;
    final bool speaking = _isSpeaking;

    final Color backgroundColor = listening
        ? AppColors.primaryYellow.withValues(alpha: 0.18)
        : speaking
            ? AppColors.lightBlue.withValues(alpha: 0.15)
            : AppColors.white;

    final Color borderColor = listening
        ? AppColors.primaryYellow
        : speaking
            ? AppColors.lightBlue
            : AppColors.primaryBlue;

    final Color iconColor = listening
        ? AppColors.black
        : AppColors.primaryBlue;

    final IconData icon = listening
        ? Icons.mic
        : speaking
            ? Icons.volume_up
            : Icons.mic_none;

    final String title = listening
        ? 'LISTENING...'
        : speaking
            ? 'SPEAKING...'
            : 'VOICE ASSISTANT READY';

    final String description = listening
        ? 'Speak your command now.'
        : speaking
            ? 'Vision Guide is speaking.'
            : 'This page is controlled by voice.';

    return Semantics(
      liveRegion: true,
      container: true,
      label: listening
          ? 'Voice assistant is listening'
          : speaking
              ? 'Voice assistant is speaking'
              : 'Voice assistant is ready',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: listening ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: listening
                    ? AppColors.primaryYellow
                    : AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: listening
                    ? AppColors.black
                    : AppColors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VOICE COMMAND CARD
  // ============================================================

  Widget _voiceCommandCard() {
    return Semantics(
      container: true,
      label:
          'Voice commands. Say list study groups. '
          'Say search followed by a subject. '
          'Say tell me about followed by a group name. '
          'Say join followed by a group name. '
          'Say leave followed by a group name. '
          'Say go back to dashboard.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: AppColors.black,
                size: 29,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPEAK YOUR COMMAND',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    '“List study groups”\n'
                    '“Search computer science”\n'
                    '“Tell me about the Python group”\n'
                    '“Join the Python group”\n'
                    '“Leave the Python group”\n'
                    '“Go back to dashboard”',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD GROUP CARD
  // ============================================================

  Widget _groupCard(
    Map<String, dynamic> group,
  ) {
    final String name =
        (group['name'] ?? 'Unnamed Study Group').toString();

    final String subject =
        (group['subject'] ?? 'Subject not specified').toString();

    final String course =
        (group['course'] ?? 'Course not specified').toString();

    final String location =
        (group['location'] ?? 'Location not specified').toString();

    final String meetingTime =
        (group['meetingTime'] ?? 'Time not specified').toString();

    final int memberCount = _getInt(
      group['memberCount'],
    );

    final int maxMembers = _getInt(
      group['maxMembers'],
    );

    final bool isMember = _isMember(group);

    return Semantics(
      container: true,
      label:
          '$name study group. '
          '$subject. '
          '$course. '
          '$location. '
          '$meetingTime. '
          '$memberCount members.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isMember
                ? AppColors.primaryYellow
                : AppColors.primaryBlue.withValues(alpha: 0.25),
            width: isMember ? 3 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: AppColors.primaryBlue,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'JOINED',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 17),

            const Divider(
              color: AppColors.grey,
              thickness: 1,
            ),

            const SizedBox(height: 12),

            _infoRow(
              Icons.location_on,
              location,
            ),

            const SizedBox(height: 11),

            _infoRow(
              Icons.access_time,
              meetingTime,
            ),

            const SizedBox(height: 11),

            _infoRow(
              Icons.people,
              maxMembers > 0
                  ? '$memberCount of $maxMembers members'
                  : '$memberCount members',
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.lightBlue.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mic,
                    color: AppColors.primaryBlue,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Voice controlled. Say '
                      '“tell me about this group”, '
                      '“join this group”, or '
                      '“leave this group”.',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                color: AppColors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryBlue,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryYellow,
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  size: 52,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'NO STUDY GROUPS FOUND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _searchText.isEmpty
                    ? 'There are currently no study groups available.'
                    : 'No study groups match $_searchText.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Say “list study groups” or '
                  '“search followed by a subject”.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryRed,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 55,
                  color: AppColors.primaryRed,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'UNABLE TO LOAD STUDY GROUPS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'There was a problem loading the study groups. '
                'You can say list study groups to try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GO BACK TO DASHBOARD
  // ============================================================

  Future<void> _goBackToDashboard() async {
    if (_isExiting) {
      return;
    }

    _isExiting = true;

    try {
      await _speech.stop();
    } catch (_) {}

    try {
      await _tts.stop();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _isSpeaking = false;
    });

    await Future.delayed(
      const Duration(milliseconds: 200),
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                23,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Semantics(
                header: true,
                label:
                    'Study Groups. '
                    'CUT Bloemfontein Campus.',
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryYellow,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: AppColors.primaryBlue,
                        size: 45,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'STUDY GROUPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'CUT BLOEMFONTEIN CAMPUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // MAIN CONTENT
            // ==================================================

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // ==========================================
                    // VOICE STATUS
                    // ==========================================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        18,
                        18,
                        10,
                      ),
                      child: _voiceStatusCard(),
                    ),

                    // ==========================================
                    // VOICE COMMAND HELP
                    // ==========================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: _voiceCommandCard(),
                    ),

                    const SizedBox(height: 14),

                    // ==========================================
                    // GROUP LIST
                    // ==========================================

                    Expanded(
                      child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: _groupsStream(),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 46,
                                    height: 46,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          AppColors.primaryBlue,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'LOADING STUDY GROUPS...',
                                    style: TextStyle(
                                      color:
                                          AppColors.primaryBlue,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            debugPrint(
                              'STUDY GROUP STREAM ERROR: '
                              '${snapshot.error}',
                            );

                            return _errorState();
                          }

                          final List<
                                  QueryDocumentSnapshot<
                                      Map<String, dynamic>>>
                              documents =
                              snapshot.data?.docs ?? [];

                          _currentGroups = documents;

                          final String search =
                              _normalize(_searchText);

                          final List<
                                  QueryDocumentSnapshot<
                                      Map<String, dynamic>>>
                              filtered =
                              search.isEmpty
                                  ? documents
                                  : documents
                                      .where(
                                        (document) {
                                          final Map<String, dynamic>
                                              data =
                                              document.data();

                                          final String name =
                                              _normalize(
                                            (data['name'] ??
                                                    '')
                                                .toString(),
                                          );

                                          final String subject =
                                              _normalize(
                                            (data['subject'] ??
                                                    '')
                                                .toString(),
                                          );

                                          final String course =
                                              _normalize(
                                            (data['course'] ??
                                                    '')
                                                .toString(),
                                          );

                                          final String location =
                                              _normalize(
                                            (data['location'] ??
                                                    '')
                                                .toString(),
                                          );

                                          return name.contains(
                                                search,
                                              ) ||
                                              subject.contains(
                                                search,
                                              ) ||
                                              course.contains(
                                                search,
                                              ) ||
                                              location.contains(
                                                search,
                                              );
                                        },
                                      )
                                      .toList();

                          if (filtered.isEmpty) {
                            return _emptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              5,
                              18,
                              30,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              return _groupCard(
                                filtered[index].data(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isExiting = true;

    _speech.stop();
    _tts.stop();

    super.dispose();
  }
}