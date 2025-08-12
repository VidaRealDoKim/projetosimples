// lib/pages/register_page.dart
import 'package:flutter/material.dart';

// Importe seu SupabaseService
import 'package:projetosimples/services/supabase_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); // Adicionado para validação
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  // Instancie seu serviço. Idealmente, injetado via Provider.
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) { // Valida o formulário
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final scaffoldMessenger = ScaffoldMessenger.of(context); // Para SnackBars
    final navigator = Navigator.of(context); // Para navegação

    try {
      final response = await _supabaseService.signUp(
        email,
        password,
        userData: {'name': name}, // Corrigido: usa userData
      );

      if (!mounted) return;

      if (response.user != null) {
        // Opcional: Inserir na tabela 'profiles' se você tiver uma e não usar triggers/functions
        // try {
        //   await Supabase.instance.client.from('profiles').insert({
        //     'id': response.user!.id,
        //     'name': name,
        //     'email': email, // Opcional, já que está no auth.users
        //   });
        // } catch (profileError) {
        //   // Logar erro, mas não necessariamente impedir o fluxo de cadastro
        //   print("Erro ao criar perfil: $profileError");
        // }


        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Cadastro realizado! Verifique seu email para confirmação (se habilitado) ou faça login.')),
        );
        navigator.pop(); // Volta para login
      } else {
        // Isso pode acontecer se a confirmação de email estiver habilitada
        // e o usuário ainda não confirmou, ou se houve um erro não AuthException.
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Usuário criado. Verifique seu email para confirmação ou tente fazer login.')),
        );
        navigator.pop(); // Volta para login
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form( // Envolve com Form
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField( // Usa TextFormField para validação
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(labelText: 'Confirme a senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmação de senha é obrigatória';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text('Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}