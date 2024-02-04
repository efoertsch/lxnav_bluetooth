import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/lxnav_cubit.dart';



class LxNavPilot extends StatefulWidget {
  @override
  _LxNavPilotState createState() => _LxNavPilotState();
}

class _LxNavPilotState extends State<LxNavPilot>
    with AfterLayoutMixin<LxNavPilot>, AutomaticKeepAliveClientMixin<LxNavPilot> {


  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<LxNavCubit>(context).getPilotInfo();
  }

  @override
  void dispose() {
    //BlocProvider.of<LxNavCubit>(context).dispose();
    super.dispose();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
    }