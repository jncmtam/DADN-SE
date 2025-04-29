import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/views/user/user_cage.dart';
import '../constants.dart';

class UserHome extends StatefulWidget {
  final String userName;
  const UserHome({super.key, required this.userName});

  @override
  State<StatefulWidget> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late int _activeDeviceCount;
  late List<UCage> _cages;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final activeCnt = await APIs.getUserActiveDevices();
      final cages = await APIs.getUserCages();

      setState(() {
        _activeDeviceCount = activeCnt;
        _cages = cages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: debugStatus,
          ),
        );
      }

      debugPrint(e.toString());
    }
  }

  Future<void> _toggleCageStatus(String cageId, bool isEnabled) async {
    try {
      await APIs.setCageStatus(cageId, isEnabled);

      final activeCnt = await APIs.getUserActiveDevices();
      setState(() {
        _activeDeviceCount = activeCnt;
        _cages = _cages.map((cage) {
          if (cage.id == cageId) {
            return UCage(
              id: cage.id,
              name: cage.name,
              deviceCount: cage.deviceCount,
              isEnabled: !isEnabled,
            );
          }
          return cage;
        }).toList();
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: lAppBarHeight,
        backgroundColor: kBase2,
        centerTitle: true,
        title: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: lAppBarFontSize,
              fontWeight: FontWeight.bold,
              color: kBase0,
            ),
            children: [
              TextSpan(text: 'Hello '),
              TextSpan(
                text: widget.userName,
                style: TextStyle(color: kBase3),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: lappBackground,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              _buildGeneralInfo(),
              SizedBox(height: 20),
              _buildCageList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: primaryButton,
        ),
        child: Text(
          '$_activeDeviceCount active devices',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryButtonContent,
          ),
        ),
      ),
    );
  }

  Widget _buildCageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cages (${_cages.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lSectionTitle,
          ),
        ),
        SizedBox(height: 10),
        ListView.separated(
          physics:
              NeverScrollableScrollPhysics(), // Important: disable inner list scroll
          shrinkWrap: true, // Important: fit content inside ListView
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemCount: _cages.length,
          itemBuilder: (context, index) {
            final cage = _cages[index];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: cage.isEnabled ? lcardBackground : ldisableBackground,
              title: Text(
                cage.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cage.isEnabled ? lCardTitle : lDisableText,
                ),
              ),
              subtitle: Text('${cage.deviceCount} devices'),
              trailing: Switch(
                value: cage.isEnabled,
                onChanged: (value) {
                  _toggleCageStatus(cage.id, cage.isEnabled);
                },
                activeColor: lOnMode,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserCageScreen(cageId: cage.id),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
