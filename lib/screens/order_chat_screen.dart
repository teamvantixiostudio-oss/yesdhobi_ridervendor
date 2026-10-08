import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/services/api_client.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';

/// Chat with the other party on an order, plus a call button.
///
/// The server keeps three separate threads per order - customer/rider,
/// customer/partner, rider/partner - and only lets you read the ones you are
/// in, so a rider cannot see what the customer said to the shop. All this
/// screen has to do is name the counterparty:
///
///   GET  /chat/{orderId}/{party}        the thread
///   POST /chat/{orderId}/{party}        send
///   POST /chat/{orderId}/{party}/read   clear the unread badge
///   GET  /chat/{orderId}/contacts       who is reachable, and their number
///
/// The phone number comes back real only while a call makes sense for that
/// stage of the order; after delivery it arrives masked with callable false,
/// and the call button greys out.
class OrderChatScreen extends StatefulWidget {
  /// Internal order id, or the order number - the server accepts either.
  final String orderId;

  /// Who you are talking to: 'customer', 'vendor' or 'rider'.
  final String party;

  /// Shown in the title bar until the server tells us their real name.
  final String partyLabel;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.party,
    required this.partyLabel,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  String? _counterpartyName;
  String? _phone;
  bool _callable = false;
  String? _stageNote;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // no socket in this app yet, so the thread is polled while it is open
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_loadContacts(), _loadMessages()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadContacts() async {
    try {
      final res = await ApiClient.instance.get('/chat/${widget.orderId}/contacts');
      final contacts = (res['contacts'] is List) ? res['contacts'] as List : const [];
      for (final c in contacts) {
        if (c is Map && (c['party']?.toString().toLowerCase() == widget.party.toLowerCase())) {
          if (!mounted) return;
          setState(() {
            _counterpartyName = c['name']?.toString();
            _phone = c['phone']?.toString();
            _callable = c['callable'] == true;
            _stageNote = c['note']?.toString();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Could not load contacts: $e');
    }
  }

  Future<void> _loadMessages({bool quiet = false}) async {
    try {
      final res = await ApiClient.instance.get('/chat/${widget.orderId}/${widget.party}');
      final data = (res['data'] is List) ? res['data'] as List : const [];
      if (!mounted) return;
      final mapped = data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      final grew = mapped.length != _messages.length;
      setState(() {
        _messages = mapped;
        if (!quiet) _error = null;
      });
      if (grew) {
        _markRead();
        _scrollToEnd();
      }
    } catch (e) {
      if (quiet || !mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    }
  }

  Future<void> _markRead() async {
    try {
      await ApiClient.instance.post('/chat/${widget.orderId}/${widget.party}/read', {});
    } catch (_) {
      // a stale unread badge is not worth bothering anyone about
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/chat/${widget.orderId}/${widget.party}', {'body': body});
      _composer.clear();
      await _loadMessages(quiet: true);
      if (!mounted) return;
      setState(() => _sending = false);
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _call() async {
    final number = _phone;
    if (!_callable || number == null || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_stageNote ?? 'Calling is not available at this stage of the order.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:${number.replaceAll(RegExp(r'[^\d+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint('Could not start the call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _counterpartyName?.isNotEmpty == true ? _counterpartyName! : widget.partyLabel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(
              widget.partyLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _call,
            icon: Icon(Icons.call, color: _callable ? AppTheme.primaryColor : const Color(0xFFCBD5E1)),
            tooltip: _callable ? 'Call $title' : (_stageNote ?? 'Calling not available'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFEE2E2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No messages yet.\nSay hello to $title.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => _bubble(_messages[i]),
                        ),
            ),
            _composerBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['mine'] == true;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine && m['senderName'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  m['senderName'].toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ),
            Text(
              m['body']?.toString() ?? '',
              style: TextStyle(fontSize: 14, color: mine ? Colors.white : const Color(0xFF0F172A), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _sending ? const Color(0xFF94A3B8) : AppTheme.primaryColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sending ? null : _send,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
