import 'package:flutter/material.dart';

class RequestStudioScreen extends StatefulWidget {
  const RequestStudioScreen({Key? key}) : super(key: key);

  @override
  State<RequestStudioScreen> createState() => _RequestStudioScreenState();
}

class _RequestStudioScreenState extends State<RequestStudioScreen> {
  String selectedMethod = 'GET';
  int selectedTab = 0;
  bool responseExpanded = true;

  final List<String> methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
  final List<String> tabs = [
    'Params',
    'Auth',
    'Headers',
    'Body',
    'Scripts',
    'Tests'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      // Request Bar
                      Container(
                        height: 80,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButton<String>(
                                value: selectedMethod,
                                underline: const SizedBox(),
                                items: methods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _getMethodColor(method),
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMethod = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: 'https://api.example.com/endpoint',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Horizontal Tabs
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: List.generate(tabs.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTab = index;
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tabs[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedTab == index
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selectedTab == index
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (selectedTab == index) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        height: 3,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Tab Content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          color: Colors.white,
                          child: _buildTabContent(),
                        ),
                      ),

                      // Response Section
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: responseExpanded ? 300 : 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  responseExpanded = !responseExpanded;
                                });
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Text(
                                      'Response',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildResponseBadge('200 OK', Colors.green),
                                    const SizedBox(width: 8),
                                    _buildResponseBadge('142ms', Colors.blue),
                                    const SizedBox(width: 8),
                                    _buildResponseBadge('2.4KB', Colors.purple),
                                    const Spacer(),
                                    Icon(
                                      responseExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_up,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (responseExpanded)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _buildResponseTab('Pretty', true),
                                          _buildResponseTab('Raw', false),
                                          _buildResponseTab('Preview', false),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            '{\n  "status": "success",\n  "data": {\n    "id": "123",\n    "name": "Example"\n  }\n}',
                                            style: TextStyle(
                                              fontFamily: 'Courier',
                                              fontSize: 13,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Side Utility Panel
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildActionButton('Save', Icons.save),
                            const SizedBox(height: 12),
                            _buildActionButton('Add to Collection', Icons.folder),
                            const SizedBox(height: 12),
                            _buildActionButton('Create Version', Icons.history),
                            const SizedBox(height: 12),
                            _buildActionButton('Generate Code', Icons.code),
                            const SizedBox(height: 12),
                            _buildActionButton('Share', Icons.share),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            'Tracely',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(width: 60),
          Text(
            'Request Studio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade900,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue.shade600;
      case 'POST':
        return Colors.green.shade600;
      case 'PUT':
        return Colors.orange.shade600;
      case 'DELETE':
        return Colors.red.shade600;
      case 'PATCH':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildTabContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tabs[selectedTab],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          if (selectedTab == 0) // Params
            _buildKeyValueTable(),
          if (selectedTab == 1) // Auth
            _buildAuthContent(),
          if (selectedTab == 2) // Headers
            _buildKeyValueTable(),
          if (selectedTab == 3) // Body
            _buildBodyContent(),
          if (selectedTab == 4) // Scripts
            _buildScriptContent(),
          if (selectedTab == 5) // Tests
            _buildTestContent(),
        ],
      ),
    );
  }

  Widget _buildKeyValueTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(value: false, onChanged: (val) {}),
                ),
                Expanded(
                  child: Text(
                    'Key',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Value',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(3, (index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(value: true, onChanged: (val) {}),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'key',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'value',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAuthContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authorization Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: 'Bearer Token',
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              'No Auth',
              'Bearer Token',
              'API Key',
              'Basic Auth',
              'OAuth 2.0'
            ].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {},
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Token',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter bearer token',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText: 'Enter request body (JSON, XML, etc.)',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
      ),
    );
  }

  Widget _buildScriptContent() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText: '// Pre-request script\nconsole.log("Request starting...");',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
      ),
    );
  }

  Widget _buildTestContent() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText:
              '// Test script\npm.test("Status code is 200", function () {\n  pm.response.to.have.status(200);\n});',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
      ),
    );
  }

  Widget _buildResponseBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: (color is MaterialColor) ? color.shade700 : color,
        ),
      ),
    );
  }

  Widget _buildResponseTab(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.grey.shade900 : Colors.grey.shade600,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 40,
              color: Colors.grey.shade900,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}