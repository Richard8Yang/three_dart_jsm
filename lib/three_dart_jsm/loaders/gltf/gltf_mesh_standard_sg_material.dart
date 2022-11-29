import 'package:three_dart/three_dart.dart';

/// Specular-Glossiness Extension
///
/// Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_pbrSpecularGlossiness

/// A sub class of StandardMaterial with some of the functionality
/// changed via the `onBeforeCompile` callback
/// @pailhead

class GLTFMeshStandardSGMaterial extends MeshStandardMaterial {
  bool isGLTFSpecularGlossinessMaterial = true;
  double? glossiness;
  Texture? glossinessMap;

  GLTFMeshStandardSGMaterial(params) : super(params) {
    type = "GLTFSpecularGlossinessMaterial";
    //various chunks that need replacing
    var specularMapParsFragmentChunk = [
      '#ifdef USE_SPECULARMAP',
      '	uniform sampler2D specularMap;',
      '#endif'
    ].join('\n');

    var glossinessMapParsFragmentChunk = [
      '#ifdef USE_GLOSSINESSMAP',
      '	uniform sampler2D glossinessMap;',
      '#endif'
    ].join('\n');

    var specularMapFragmentChunk = [
      'vec3 specularFactor = specular;',
      '#ifdef USE_SPECULARMAP',
      '	vec4 texelSpecular = texture2D( specularMap, vUv );',
      '	// reads channel RGB, compatible with a glTF Specular-Glossiness (RGBA) texture',
      '	specularFactor *= texelSpecular.rgb;',
      '#endif'
    ].join('\n');

    var glossinessMapFragmentChunk = [
      'float glossinessFactor = glossiness;',
      '#ifdef USE_GLOSSINESSMAP',
      '	vec4 texelGlossiness = texture2D( glossinessMap, vUv );',
      '	// reads channel A, compatible with a glTF Specular-Glossiness (RGBA) texture',
      '	glossinessFactor *= texelGlossiness.a;',
      '#endif'
    ].join('\n');

    var lightPhysicalFragmentChunk = [
      'PhysicalMaterial material;',
      'material.diffuseColor = diffuseColor.rgb * ( 1. - max( specularFactor.r, max( specularFactor.g, specularFactor.b ) ) );',
      'vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );',
      'float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );',
      'material.specularRoughness = max( 1.0 - glossinessFactor, 0.0525 ); // 0.0525 corresponds to the base mip of a 256 cubemap.',
      'material.specularRoughness += geometryRoughness;',
      'material.specularRoughness = min( material.specularRoughness, 1.0 );',
      'material.specularColor = specularFactor;',
    ].join('\n');

    onBeforeCompile = (shader) {
      shader.uniforms["specular"] =
          (specular != null) ? specular : Color.fromHex(0xffffff);
      shader.uniforms["specular"] = (glossiness != null) ? glossiness : 1;
      if (specularMap != null) {
        // USE_UV is set by the renderer for specular maps
        defines!["USE_SPECULARMAP"] = '';
        shader.uniforms["specularMap"] = specularMap;
      } else {
        // delete this.defines.USE_SPECULARMAP;
        defines!.remove("USE_SPECULARMAP");
        shader.uniforms["specularMap"] = null;
      }
      if (glossinessMap != null) {
        defines!["USE_GLOSSINESSMAP"] = '';
        defines!["USE_UV"] = '';
        shader.uniforms["glossinessMap"] = glossinessMap;
      } else {
        // delete this.defines.USE_GLOSSINESSMAP;
        // delete this.defines.USE_UV;
        defines!.remove("USE_GLOSSINESSMAP");
        defines!.remove("USE_UV");
        shader.uniforms["glossinessMap"] = null;
      }

      shader.fragmentShader = shader.fragmentShader
          .replace('uniform float roughness;', 'uniform vec3 specular;')
          .replace('uniform float metalness;', 'uniform float glossiness;')
          .replace('#include <roughnessmap_pars_fragment>',
              specularMapParsFragmentChunk)
          .replace('#include <metalnessmap_pars_fragment>',
              glossinessMapParsFragmentChunk)
          .replace('#include <roughnessmap_fragment>', specularMapFragmentChunk)
          .replace(
              '#include <metalnessmap_fragment>', glossinessMapFragmentChunk)
          .replace('#include <lights_physical_fragment>',
              lightPhysicalFragmentChunk);
    };

    // delete this.metalness;
    // delete this.roughness;
    // delete this.metalnessMap;
    // delete this.roughnessMap;

    setValues(params);
  }

  @override
  void setValue(String key, newValue) {
    if (key == "glossiness") {
      glossiness = newValue;
    } else if (key == "glossinessMap") {
      glossinessMap = newValue;
    } else {
      super.setValue(key, newValue);
    }
  }

  @override
  copy(Material source) {
    super.copy(source);

    var s = source as GLTFMeshStandardSGMaterial;

    specularMap = s.specularMap;
    specular!.copy(s.specular!);
    glossinessMap = s.glossinessMap;
    glossiness = s.glossiness;
    // delete this.metalness;
    // delete this.roughness;
    // delete this.metalnessMap;
    // delete this.roughnessMap;
    return this;
  }
}
