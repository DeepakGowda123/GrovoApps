import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatelessWidget {
  final User user;
  const AccountScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final Color _primaryColor = const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Color(0x80000000),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _primaryColor,
                          _primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.displayName ?? 'Farmer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildAccountSection(
                icon: Icons.person_outline,
                title: 'Personal Information',
                items: [
                  {'title': 'Email', 'value': user.email ?? 'No email provided'},
                  {'title': 'Phone', 'value': user.phoneNumber ?? 'Not provided'},
                  {'title': 'User ID', 'value': user.uid.substring(0, 8) + '...'},
                ],
                onTap: () {},
                primaryColor: _primaryColor,
              ),
              _buildAccountSection(
                icon: Icons.agriculture_outlined,
                title: 'Farm Information',
                items: [
                  {'title': 'Farm Name', 'value': 'Green Valley Farm'},
                  {'title': 'Farm Size', 'value': '120 Acres'},
                  {'title': 'Main Crops', 'value': 'Corn, Wheat, Soybeans'},
                ],
                onTap: () {},
                primaryColor: _primaryColor,
              ),
              _buildAccountSection(
                icon: Icons.settings_outlined,
                title: 'Settings',
                items: [],
                onTap: () {},
                primaryColor: _primaryColor,
                isAction: true,
              ),
              _buildAccountSection(
                icon: Icons.help_outline,
                title: 'Help & Support',
                items: [],
                onTap: () {},
                primaryColor: _primaryColor,
                isAction: true,
              ),
              _buildAccountSection(
                icon: Icons.logout,
                title: 'Log Out',
                items: [],
                onTap: () {
                  FirebaseAuth.instance.signOut();
                },
                primaryColor: _primaryColor,
                isAction: true,
                isLogout: true,
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection({
    required IconData icon,
    required String title,
    required List<Map<String, String>> items,
    required Function() onTap,
    required Color primaryColor,
    bool isAction = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: isLogout ? Colors.redAccent : primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLogout ? Colors.redAccent : const Color(0xFF424242),
                      ),
                    ),
                    const Spacer(),
                    if (isAction)
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                  ],
                ),
                if (items.isNotEmpty) const SizedBox(height: 12),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          item['value']!,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}