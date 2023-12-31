// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill_extensions/presentation/embeds/editor/shims/dart_ui_real.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;

import 'package:weaving/gen/strings.g.dart';

typedef OnQuillSave = void Function(String, String, String);
typedef OnQuillPreviewImageSave = void Function(Uint8List);

class Editor extends StatefulWidget {
  const Editor(
      {super.key, this.saveToJson, this.savedData = "", this.savePreview});
  final OnQuillSave? saveToJson;
  final String savedData;
  final OnQuillPreviewImageSave? savePreview;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final FocusNode _focusNode = FocusNode();

  late final QuillController _controller;

  @override
  void dispose() {
    _controller.dispose();
    quillScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Document doc;
    try {
      doc = Document.fromJson(jsonDecode(widget.savedData));
    } catch (_) {
      doc = Document()..insert(0, '');
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildWelcomeEditor(context);
  }

  final ScrollController quillScrollController = ScrollController();

  QuillEditor get quillEditor {
    if (kIsWeb) {
      return QuillEditor(
        focusNode: _focusNode,
        scrollController: quillScrollController,
        configurations: QuillEditorConfigurations(
          builder: (context, rawEditor) {
            return rawEditor;
          },
          placeholder: t.catalogs.editor.addContent,
          readOnly: false,
          scrollable: true,
          autoFocus: false,
          expands: false,
          padding: EdgeInsets.zero,
          // onTapUp: (details, p1) {
          //   return _onTripleClickSelection();
          // },
          customStyles: const DefaultStyles(
            h1: DefaultTextBlockStyle(
              TextStyle(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              VerticalSpacing(16, 0),
              VerticalSpacing(0, 0),
              null,
            ),
            sizeSmall: TextStyle(fontSize: 9),
          ),
          embedBuilders: [
            ...FlutterQuillEmbeds.editorWebBuilders(),
            // TimeStampEmbedBuilderWidget()
          ],
        ),
      );
    }
    return QuillEditor(
      configurations: QuillEditorConfigurations(
        builder: (context, rawEditor) {
          return rawEditor;
        },
        placeholder: t.catalogs.editor.addContent,
        readOnly: false,
        autoFocus: false,
        enableSelectionToolbar: isMobile(supportWeb: false),
        expands: false,
        padding: EdgeInsets.zero,
        onImagePaste: _onImagePaste,
        // onTapUp: (details, p1) {
        //   return _onTripleClickSelection();
        // },
        customStyles: const DefaultStyles(
          h1: DefaultTextBlockStyle(
            TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w300,
            ),
            VerticalSpacing(16, 0),
            VerticalSpacing(0, 0),
            null,
          ),
          sizeSmall: TextStyle(fontSize: 9),
          subscript: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontFeatures: [FontFeature.subscripts()],
          ),
          superscript: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontFeatures: [FontFeature.superscripts()],
          ),
        ),
        embedBuilders: [
          ...FlutterQuillEmbeds.editorBuilders(
            imageEmbedConfigurations:
                const QuillEditorImageEmbedConfigurations(),
          ),
          // TimeStampEmbedBuilderWidget()
        ],
      ),
      scrollController: quillScrollController,
      focusNode: _focusNode,
    );
  }

  /// When inserting an image
  OnImageInsertCallback get onImageInsert {
    return (image, controller) async {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      final newImage = croppedFile?.path;
      if (newImage == null) {
        return;
      }
      controller.insertImageBlock(imageSource: newImage);
    };
  }

  QuillToolbar get quillToolbar {
    final customButtons = [
      QuillToolbarCustomButtonOptions(
        tooltip: t.catalogs.editor.saveAsJson,
        icon: const Icon(Icons.save),
        onPressed: () {
          if (widget.saveToJson != null) {
            final j = jsonEncode(_controller.document.toDelta().toJson());
            final t = _controller.document.toPlainText();
            // ignore: no_leading_underscores_for_local_identifiers
            String _abstract;
            if (t.length > 20) {
              _abstract = t.substring(0, 20);
            } else {
              _abstract = t;
            }
            _abstract = "${_abstract.replaceAll("\n", "")} ...";
            widget.saveToJson!(j, t, _abstract);
          }
          Navigator.of(context).pop();
        },
      ),
      QuillToolbarCustomButtonOptions(
        tooltip: t.catalogs.editor.savePreview,
        icon: const Icon(Icons.save_as),
        onPressed: () async {
          if (widget.savePreview != null) {
            try {
              RenderRepaintBoundary repaintBoundary = _shotKey.currentContext!
                  .findRenderObject() as RenderRepaintBoundary;
              var resultImage = await repaintBoundary.toImage();
              ByteData? byteData =
                  await resultImage.toByteData(format: ui.ImageByteFormat.png);
              if (byteData != null) {
                Uint8List pngBytes = byteData.buffer.asUint8List();
                widget.savePreview!(pngBytes);
              }
            } catch (_) {}
          }
        },
      ),
      QuillToolbarCustomButtonOptions(
        tooltip: t.catalogs.editor.exit,
        icon: const Icon(Icons.exit_to_app),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];
    if (kIsWeb) {
      return QuillToolbar(
        configurations: QuillToolbarConfigurations(
          customButtons: customButtons,
          embedButtons: FlutterQuillEmbeds.toolbarButtons(
            // formulaButtonOptions: const QuillToolbarFormulaButtonOptions(),
            cameraButtonOptions: const QuillToolbarCameraButtonOptions(),
            imageButtonOptions: QuillToolbarImageButtonOptions(
              imageButtonConfigurations: QuillToolbarImageConfigurations(
                onImageInsertedCallback: (image) async {
                  _onImagePickCallback(File(image));
                },
                onImageInsertCallback: onImageInsert,
              ),
            ),
          ),
          buttonOptions: QuillToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              afterButtonPressed: _focusNode.requestFocus,
            ),
          ),
        ),
      );
    }
    if (isDesktop(supportWeb: false)) {
      return QuillToolbar(
        configurations: QuillToolbarConfigurations(
          customButtons: customButtons,
          embedButtons: FlutterQuillEmbeds.toolbarButtons(
            cameraButtonOptions: const QuillToolbarCameraButtonOptions(),
            imageButtonOptions: QuillToolbarImageButtonOptions(
              imageButtonConfigurations: QuillToolbarImageConfigurations(
                onImageInsertedCallback: (image) async {
                  _onImagePickCallback(File(image));
                },
              ),
            ),
          ),
          showAlignmentButtons: true,
          buttonOptions: QuillToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              afterButtonPressed: _focusNode.requestFocus,
            ),
          ),
        ),
      );
    }
    return QuillToolbar(
      configurations: QuillToolbarConfigurations(
        customButtons: customButtons,
        embedButtons: FlutterQuillEmbeds.toolbarButtons(
          // formulaButtonOptions: const QuillToolbarFormulaButtonOptions(),
          cameraButtonOptions: const QuillToolbarCameraButtonOptions(),
          videoButtonOptions: QuillToolbarVideoButtonOptions(
            videoConfigurations: QuillToolbarVideoConfigurations(
              onVideoInsertedCallback: (video) =>
                  _onVideoPickCallback(File(video)),
            ),
          ),
          imageButtonOptions: QuillToolbarImageButtonOptions(
            imageButtonConfigurations: QuillToolbarImageConfigurations(
              onImageInsertCallback: onImageInsert,
              onImageInsertedCallback: (image) async {
                _onImagePickCallback(File(image));
              },
            ),
            // provide a callback to enable picking images from device.
            // if omit, "image" button only allows adding images from url.
            // same goes for videos.
            // onImagePickCallback: _onImagePickCallback,
            // uncomment to provide a custom "pick from" dialog.
            // mediaPickSettingSelector: _selectMediaPickSetting,
            // uncomment to provide a custom "pick from" dialog.
            // cameraPickSettingSelector: _selectCameraPickSetting,
          ),
          // videoButtonOptions: QuillToolbarVideoButtonOptions(
          //   onVideoPickCallback: _onVideoPickCallback,
          // ),
        ),
        showAlignmentButtons: true,
        buttonOptions: QuillToolbarButtonOptions(
          base: QuillToolbarBaseButtonOptions(
            afterButtonPressed: _focusNode.requestFocus,
          ),
        ),
      ),
      // afterButtonPressed: _focusNode.requestFocus,
    );
  }

  final GlobalKey _shotKey = GlobalKey();

  Widget _buildWelcomeEditor(BuildContext context) {
    return SafeArea(
      child: QuillProvider(
        configurations: QuillConfigurations(
          controller: _controller,
          sharedConfigurations: QuillSharedConfigurations(
            animationConfigurations: QuillAnimationConfigurations.enableAll(),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 15,
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: RepaintBoundary(
                  key: _shotKey,
                  child: quillEditor,
                ),
              ),
            ),
            kIsWeb
                ? Expanded(
                    child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: quillToolbar,
                  ))
                : Container(
                    child: quillToolbar,
                  )
          ],
        ),
      ),
    );
  }

  // Future<String?> _openFileSystemPickerForDesktop(BuildContext context)
  // async {
  //   return await FilesystemPicker.open(
  //     context: context,
  //     rootDirectory: await getApplicationDocumentsDirectory(),
  //     fsType: FilesystemType.file,
  //     fileTileSelectMode: FileTileSelectMode.wholeTile,
  //   );
  // }

  // Renders the image picked by imagePicker from local file storage
  // You can also upload the picked image to any server (eg : AWS s3
  // or Firebase) and then return the uploaded image URL.
  Future<String> _onImagePickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${path.basename(file.path)}');
    return copiedFile.path.toString();
  }

  // Future<String?> _webImagePickImpl(
  //     OnImagePickCallback onImagePickCallback) async {
  //   final result = await FilePicker.platform.pickFiles();
  //   if (result == null) {
  //     return null;
  //   }

  //   // Take first, because we don't allow picking multiple files.
  //   final fileName = result.files.first.name;
  //   final file = File(fileName);

  //   return onImagePickCallback(file);
  // }

  // Renders the video picked by imagePicker from local file storage
  // You can also upload the picked video to any server (eg : AWS s3
  // or Firebase) and then return the uploaded video URL.
  Future<String> _onVideoPickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${path.basename(file.path)}');
    return copiedFile.path.toString();
  }

  // // ignore: unused_element
  // Future<MediaPickSetting?> _selectMediaPickSetting(BuildContext context) =>
  //     showDialog<MediaPickSetting>(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         contentPadding: EdgeInsets.zero,
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextButton.icon(
  //               icon: const Icon(Icons.collections),
  //               label: const Text('Gallery'),
  //               onPressed: () => Navigator.pop(ctx,
  // MediaPickSetting.gallery),
  //             ),
  //             TextButton.icon(
  //               icon: const Icon(Icons.link),
  //               label: const Text('Link'),
  //               onPressed: () => Navigator.pop(ctx, MediaPickSetting.link),
  //             )
  //           ],
  //         ),
  //       ),
  //     );

  // // ignore: unused_element
  // Future<MediaPickSetting?> _selectCameraPickSetting(BuildContext context) =>
  //     showDialog<MediaPickSetting>(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         contentPadding: EdgeInsets.zero,
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextButton.icon(
  //               icon: const Icon(Icons.camera),
  //               label: const Text('Capture a photo'),
  //               onPressed: () => Navigator.pop(ctx, MediaPickSetting.camera),
  //             ),
  //             TextButton.icon(
  //               icon: const Icon(Icons.video_call),
  //               label: const Text('Capture a video'),
  //               onPressed: () => Navigator.pop(ctx, MediaPickSetting.video),
  //             )
  //           ],
  //         ),
  //       ),
  //     );

  Widget _buildMenuBar(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Divider(
          thickness: 2,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
        ListTile(
          title: const Center(
              child: Text(
            'Read only demo',
          )),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _openReadOnlyPage,
        ),
        Divider(
          thickness: 2,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
      ],
    );
  }

  void _openReadOnlyPage() {
    Navigator.pop(super.context);
    Navigator.push(
      super.context,
      MaterialPageRoute(
        builder: (context) => Container(),
      ),
    );
  }

  Future<String> _onImagePaste(Uint8List imageBytes) async {
    // Saves the image to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
      '${appDocDir.path}/${path.basename('${DateTime.now().millisecondsSinceEpoch}.png')}',
    ).writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }

  static void _insertTimeStamp(QuillController controller, String string) {
    controller.document.insert(controller.selection.extentOffset, '\n');
    controller.updateSelection(
      TextSelection.collapsed(
        offset: controller.selection.extentOffset + 1,
      ),
      ChangeSource.local,
    );

    controller.document.insert(
      controller.selection.extentOffset,
      string,
    );

    controller.updateSelection(
      TextSelection.collapsed(
        offset: controller.selection.extentOffset + 1,
      ),
      ChangeSource.local,
    );

    controller.document.insert(controller.selection.extentOffset, ' ');
    controller.updateSelection(
      TextSelection.collapsed(
        offset: controller.selection.extentOffset + 1,
      ),
      ChangeSource.local,
    );

    controller.document.insert(controller.selection.extentOffset, '\n');
    controller.updateSelection(
      TextSelection.collapsed(
        offset: controller.selection.extentOffset + 1,
      ),
      ChangeSource.local,
    );
  }
}
