import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A334A)),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & App Name
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006B4D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MedRemind',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A334A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Heading
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A334A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Start your health journey today',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Full Name Field
              const Text(
                'Full Name',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A334A),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Sarah Johnson',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFF0A334A),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              const Text(
                'Email Address',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A334A),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'sarah@email.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF0A334A),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A334A),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF0A334A),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF0A334A),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    activeColor: const Color(0xFF006B4D),
                    onChanged: (val) {
                      setState(() {
                        _agreeToTerms = val ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to Terms of Service and Privacy Policy',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Create Account Button
              ElevatedButton(
                onPressed: () {},
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
