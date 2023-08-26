import 'package:chat/utils/constants.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Avatar {
  final int id;
  final String imagePath;

  Avatar({required this.id, required this.imagePath});
}

List<Avatar> avatars = [
  Avatar(id: 2131230895, imagePath: 'assets/if_adium_49043.png'),
  Avatar(id: 2131230851, imagePath: 'assets/driver_1.png'),
  Avatar(id: 2131230897, imagePath: 'assets/if_b02.png'),
  Avatar(id: 2131230901, imagePath: 'assets/if_co1.png'),
  Avatar(id: 2131230900, imagePath: 'assets/if_cattle_tuck_88245.png'),
  Avatar(id: 2131230903, imagePath: 'assets/if_daf_girder_truck.png'),
  Avatar(id: 2131230904, imagePath: 'assets/if_daf_tiper.png'),
  Avatar(id: 2131230907, imagePath: 'assets/if_fa03.png'),
  Avatar(id: 2131230908, imagePath: 'assets/if_fd.png'),
  Avatar(id: 2131230909, imagePath: 'assets/if_fe05.png'),
  Avatar(id: 2131230910, imagePath: 'assets/if_fi01.png'),
  Avatar(id: 2131230911, imagePath: 'assets/if_fire_escape.png'),
  Avatar(id: 2131230913, imagePath: 'assets/if_foden_concrete_tuck.png'),
  Avatar(id: 2131230917, imagePath: 'assets/if_h05_.png'),
  Avatar(id: 2131230918, imagePath: 'assets/if_jo1.png'),
  Avatar(id: 2131230920, imagePath: 'assets/if_lorry_green.png'),
  Avatar(id: 2131230927, imagePath: 'assets/if_tractor_unit_black_22998.png'),
  Avatar(id: 2131230934, imagePath: 'assets/if_truck_yellow.png'),
  Avatar(id: 2131230896, imagePath: 'assets/if_ambulance_45490.png'),
  Avatar(id: 2131230899, imagePath: 'assets/if_bus_front_01_1988879.png'),
  Avatar(id: 2131230898, imagePath: 'assets/if_bus_47405.png'),
  Avatar(id: 2131230902, imagePath: 'assets/if_coraline_49044.png'),
  Avatar(id: 2131230905, imagePath: 'assets/if_diagram_v2_32_37152.png'),
  Avatar(id: 2131230906, imagePath: 'assets/if_evernote_49045.png'),
  Avatar(id: 2131230912, imagePath: 'assets/if_firefox_49046.png'),
  Avatar(id: 2131230914, imagePath: 'assets/if_freebsd_49049.png'),
  Avatar(id: 2131230915, imagePath: 'assets/if_freebsd_daemon_386463.png'),
  Avatar(id: 2131230916, imagePath: 'assets/if_guard_45502.png'),
  Avatar(id: 2131230919, imagePath: 'assets/if_linux_tox_386476.png'),
  Avatar(id: 2131230921, imagePath: 'assets/if_monkeys_audio_49052.png'),
  Avatar(id: 2131230922, imagePath: 'assets/if_nike_37862.png'),
  Avatar(id: 2131230923, imagePath: 'assets/if_policeman_45483.png'),
  Avatar(id: 2131230924, imagePath: 'assets/if_receptionist_45441.png'),
  Avatar(id: 2131230925, imagePath: 'assets/if_rocket_406798.png'),
  Avatar(id: 2131230926, imagePath: 'assets/if_school_bus_44999.png'),
  Avatar(id: 2131230928, imagePath: 'assets/if_transportation_service_45471.png'),
  Avatar(id: 2131230932, imagePath: 'assets/if_truck_back_03_2140057.png'),
  Avatar(id: 2131230933, imagePath: 'assets/if_truck_front_01_1988878.png'),
  Avatar(id: 2131230929, imagePath: 'assets/if_truck_37865.png'),
  Avatar(id: 2131230930, imagePath: 'assets/if_truck_44870.png'),
  Avatar(id: 2131230931, imagePath: 'assets/if_truck_45435.png'),
  Avatar(id: 2131230935, imagePath: 'assets/if_twitter_49054.png'),
  Avatar(id: 2131230853, imagePath: 'assets/girls_female_woman_pers.png'),
  Avatar(id: 2131230856, imagePath: 'assets/head_medical_man_avatar.png'),
  Avatar(id: 2131230893, imagePath: 'assets/icons8.png'),
  Avatar(id: 2131230894, imagePath: 'assets/icons8_semi_truck_50.png'),
  Avatar(id: 2131230971, imagePath: 'assets/police_avatar_person.png'),
  Avatar(id: 2131230972, imagePath: 'assets/police_wome.png'),
];

void showAvatarSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white, // Set the background color to white
        insetPadding: EdgeInsets.all(100.0),
        child: Container(
          width: MediaQuery.of(context).size.width *
              0.8, // Set width to 80% of the screen width
          padding: EdgeInsets.all(16.0),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              Avatar avatar = avatars[index];
              return GestureDetector(
                onTap: () {
                  // Handle avatar selection

                  int currentUserAvatarId = avatar.id;
                  String currentUserAvatarImagePath = avatar.imagePath;
                  print(
                      'Selected currentUserAvatarImagePath $currentUserAvatarImagePath');
                  // Store the selected avatar ID in SharedPreferences
                  SharedPrefs.setInt(
                      SharedPrefsKeys.CURRENT_USER_AVATAR_ID, currentUserAvatarId);
                  SharedPrefs.setString(
                      SharedPrefsKeys.CURRENT_USER_AVATAR_IMAGE_PATH, currentUserAvatarImagePath);

                  // Call your backend API to update the avatar ID for the user
                  Navigator.pop(context); // Close the dialog
                },
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Container(
                    height: 64,
                    width: 64, // Customize the avatar width
                    child: Image.asset(
                      avatar.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

void _handleAvatarSelection(BuildContext context, int selectedAvatarId) async {
  print('Selected Avatar id $selectedAvatarId');
  await storeSelectedAvatarId(selectedAvatarId);
  Navigator.pop(context);
}

Future<void> storeSelectedAvatarId(int selectedAvatarId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt(SharedPrefsKeys.SELECTED_AVATAR_ID, selectedAvatarId);
}
