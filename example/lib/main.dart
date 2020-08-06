import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Rerderable List',
      theme: ThemeData(
        dividerColor: Color(0x50000000),
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Reorderable List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class ItemData {
  ItemData({this.data, this.id});

  final String data;

  final int id;
}

enum DraggingMode {
  iOS,
  Android,
}

class _MyHomePageState extends State<MyHomePage> {
  List<ItemData> _items;
  _MyHomePageState() {
    _items = List();
    for (int i = 0; i < 3; ++i) {
      String label = "List item $i";
      if (i == 1) {
        label += ". This item has a long label and will be wrapped.";
      }
      _items.add(ItemData(data: label, id: i));
    }
  }

  // Returns index of item with given key
  int _indexOfKey(Key key) {
    return _items.indexWhere((ItemData d) => ValueKey(d.id) == key);
  }

  bool _onReorder(Key key, Key newKey) {
    int draggingIndex = _indexOfKey(key);
    int newPositionIndex = _indexOfKey(newKey);

    final draggedItem = _items[draggingIndex];
    _items.removeAt(draggingIndex);
    _items.insert(newPositionIndex, draggedItem);
    setState(() {
      debugPrint("Reordering $key -> $newKey");
    });
    return true;
  }

  void _onReorderDone(Key key) {
    final draggedItem = _items[_indexOfKey(key)];
    debugPrint("Reordering finished for ${draggedItem.data}}");
  }

  //
  // Reordering works by having ReorderableList widget in hierarchy
  // containing ReorderableItems widgets
  //

  DraggingMode _draggingMode = DraggingMode.iOS;

  Widget build(BuildContext context) {
    return Scaffold(
      body: ReorderableList(
        onReorder: this._onReorder,
        //onReorderDone: this._onReorderDone,
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            ListTile(title: Text("Header"),),
            ..._items.mapIndexed((it, index) => ReorderableListTile(
              onDragBuilder: (child) =>
                  Container(
                      child: child,
                      //decoration: BoxDecoration(color: Color(0xD0FFFFFF))
                      decoration: BoxDecoration(color: Colors.green)
                  ),
              key: ValueKey(it.id),
              // first and last attributes affect border drawn during dragging
              //isFirst: index == 0,
              //isLast: index == _items.length - 1,
              dragHandleEnabled: _draggingMode == DraggingMode.iOS,
              child: Text(it.data, style: Theme.of(context).textTheme.subtitle),
              builder: (handle) => ListTile(title: Text(it.data), trailing: handle),
            ),
            ),
            ListTile(title: Text("Footer"),),
          ],
        ),
      ),
    ));
  }
}

extension ListX<E> on List<E> {
  Iterable<T> mapIndexed<T>(T f(E e, int i)) {
    var i = 0;
    return this.map((e) => f(e, i++));
  }
}

class ReorderableListTile extends StatelessWidget {
  const ReorderableListTile({
    @required
    this.key,
    this.child,
    this.dragHandle,
    this.builder,
    this.dragHandleEnabled = true,
    //this.isFirst = false,
    //this.isLast = false,
    this.onDragBuilder,
  }) : assert(child != null || builder != null), super();

  final Widget child;
  final Key key;
  //final bool isFirst;
  //final bool isLast;
  final bool dragHandleEnabled;
  final Widget dragHandle;
  final Widget Function(Widget child) onDragBuilder;
  final Widget Function(Widget dragHandle) builder;

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    // For iOS dragging mode, there will be drag handle on the right that triggers
    // reordering; For android mode it will be just an empty container
    Widget dragHandler = dragHandleEnabled
        ? ReorderableListener(
            child: dragHandle ?? Icon(Icons.drag_handle),
          )
        : Container();

    Widget content = SafeArea(
          top: false,
          bottom: false,
          child: Opacity(
            // hide content for placeholder
            opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
            child: builder?.call(dragHandler) ?? ListTile(
              title: child,
              trailing: dragHandler,
            ),
          ));

    if (state == ReorderableItemState.dragProxy ||
        state == ReorderableItemState.dragProxyFinished) {
      content = onDragBuilder?.call(content) ?? content;
    }

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    if (!dragHandleEnabled) {
      content = DelayedReorderableListener(
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: key,
        childBuilder: _buildChild);
  }
}

class ReorderableColumn extends StatelessWidget {
  ReorderableColumn(this.children);
  List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: children
    );
  }
}

