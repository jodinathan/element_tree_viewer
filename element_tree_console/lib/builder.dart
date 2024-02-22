import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/generator.dart';

Builder metadataLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      MetadataLibraryGenerator(),
      generatedExtension: '.analyzer.dart',
    );
