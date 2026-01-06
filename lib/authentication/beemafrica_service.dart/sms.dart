import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BeemSmsScreen extends StatefulWidget {
  const BeemSmsScreen({Key? key}) : super(key: key);

  @override
  State<BeemSmsScreen> createState() => _BeemSmsScreenState();
}

class _BeemSmsScreenState extends State<BeemSmsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  
  // Beem Africa API Credentials
  final String _apiKey = 'f7f7c33c7361b547';
  final String _secretKey = '4ee49d91ba3e6cba609de29d384a91ba49cf72c39749d88c0aea3cf53929ad54';
  final String _senderId = 'SmartChaja';
  
  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.green;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getBasicAuth() {
    // Basic Auth format: base64(api_key:secret_key)
    String credentials = '$_apiKey:$_secretKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));
    print('API Key: $_apiKey');
    print('Base64 Credentials: $base64Credentials');
    return 'Basic $base64Credentials';
  }

  Future<void> _sendSms() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Clean phone number (remove spaces, dashes, plus signs)
      String cleanPhone = _phoneController.text
          .replaceAll(RegExp(r'[^\d]'), '');
      
      print('Sending to: $cleanPhone');
      print('Sender ID: $_senderId');
      print('Message: ${_messageController.text}');
      
      final requestBody = {
        'source_addr': _senderId,
        'schedule_time': '',
        'encoding': 0,
        'message': _messageController.text,
        'recipients': [
          {
            'recipient_id': 1,
            'dest_addr': cleanPhone,
          }
        ],
      };
      
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://apisms.beem.africa/v1/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuth(),
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200 && responseData['successful'] == true) {
          _statusMessage = 'Message sent successfully! ✓\nValid: ${responseData['valid']}, Request ID: ${responseData['request_id']}';
          _statusColor = Colors.green;
          _phoneController.clear();
          _messageController.clear();
        } else {
          _statusMessage = 'Error: ${responseData['message'] ?? 'Failed to send message'}\nCode: ${responseData['code'] ?? 'N/A'}';
          _statusColor = Colors.red;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
        _statusColor = Colors.red;
      });
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SMS'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sms,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Phone Number Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '255700000001',
                        prefixIcon: Icon(Icons.phone, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
                        if (cleaned.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      maxLength: 160,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Enter your message here...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.message, color: Colors.blue.shade700),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Send Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendSms,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Send SMS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status Message
                  if (_statusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusColor == Colors.green
                                ? Icons.check_circle
                                : Icons.error,
                            color: _statusColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter phone number with country code (e.g., 255700000001)',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}