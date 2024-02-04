import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lxnav_bluetooth/app/custom_styles.dart';
import 'package:lxnav_bluetooth/lxnav/bloc/lxnav_data_state.dart';
import 'package:lxnav_bluetooth/lxnav/data/lxnav_logbook_entry.dart';

import '../bloc/lxnav_cubit.dart';

class LxNavLogbook extends StatefulWidget {
  @override
  _LxNavLogbookState createState() => _LxNavLogbookState();
}

class _LxNavLogbookState extends State<LxNavLogbook>
    with AfterLayoutMixin<LxNavLogbook> {
  bool _isWorking = false;

  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<LxNavCubit>(context).getLogBook();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
            children: [_getLogBookList(), _getConnectionProgressIndicator()]));
  }

  BlocBuilder<LxNavCubit, LxNavDataState> _getLogBookList() {
    return BlocBuilder<LxNavCubit, LxNavDataState>(
        buildWhen: (previous, current) {
      return (current is LxNavLogBookState); // to set values
    }, builder: (context, state) {
      if (state is LxNavLogBookState) {
        return _getLogbookListView(state.logbook);
      } else {
        return SizedBox.shrink();
      }
    });
  }

  Widget _getConnectionProgressIndicator() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavBtIsWorkingState) {
        _isWorking = state.isWorking;
      }
    }, builder: (context, state) {
      return Visibility(
          visible: _isWorking,
          child: Container(
            child: AbsorbPointer(
                absorbing: true,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                )),
            alignment: Alignment.center,
            color: Colors.transparent,
          ));
    });
  }

  Widget _getLogbookListView(List<LxNavLogbookEntry> logbook) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: logbook.length,
        itemBuilder: (context, index) {
          final logbookEntry = logbook[index];
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.only(right: 8.0),
                      //   child: _formatLogbook(
                      //       logbookEntry.flightNumber.toString()),
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _formatLogbook(logbookEntry.reformattedDate()),
                      ),
                      Padding(
                        child: _formatLogbook("Flight time:"),
                        padding: const EdgeInsets.only(right: 8.0),
                      ),
                      Padding(
                        child: _formatLogbook(logbookEntry.getFlightTime()),
                        padding: const EdgeInsets.only(right: 8.0),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.arrow_drop_up),
                      ),
                      Padding(
                        child: _formatLogbook(logbookEntry.startTime),
                        padding: const EdgeInsets.only(right: 8.0),
                      ),
                      Icon(Icons.arrow_drop_down),
                      Padding(
                        child: _formatLogbook(logbookEntry.endTime),
                        padding: const EdgeInsets.only(right: 8.0),
                      ),
                    ],
                  ),
                  Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(left:16.0, right: 8.0),
                      child: _formatLogbook(logbookEntry.filename),
                    ),
                    _formatLogbook(
                        (logbookEntry.filesize / 1000).toStringAsFixed(1) +
                            "KB")
                  ])
                ],
              ));
        },
      ),
    );
  }

  Widget _formatLogbook(String text) {
    return Text(text, style: textStyleBlackFontSize18);
  }
}
