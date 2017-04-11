///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 Nailson <nailsonnego@gmail.com>
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
///////////////////////////////////////////////////////////////////////////////////

package nail.otlib.things
{
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.filters.ColorMatrixFilter;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Endian;
    
    import nail.errors.NullArgumentError;
    import nail.logging.Log;
    import nail.otlib.core.Version;
    import nail.otlib.core.Versions;
    import nail.otlib.geom.Rect;
    import nail.otlib.sprites.Sprite;
    import nail.otlib.sprites.SpriteData;
    import nail.otlib.things.FrameDuration;
    import nail.otlib.utils.ColorUtils;
    import nail.otlib.utils.OTFormat;
    import nail.otlib.utils.SpriteUtils;
    import nail.otlib.utils.ThingUtils;
    import nail.utils.StringUtil;
    
    public class ThingData
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var thing:ThingType;
        public var sprites:Vector.<SpriteData>;
		public var sprites_2:Vector.<SpriteData>;
        
        //--------------------------------------
        // Getters / Setters 
        //--------------------------------------
        
        public function get id():uint { return thing ? thing.id : 0; }
        public function get category():String { return thing ? thing.category : null; }
		public function get length():uint { return sprites ? sprites.length : 0; }
        public function get length_2():uint { return sprites_2 ? sprites_2.length : 0; }
		
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingData()
        {
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function clone():ThingData
        {
            var spritesCopy:Vector.<SpriteData> = new Vector.<SpriteData>();
            var length:uint = sprites.length;
            for (var i:uint = 0; i < length; i++) {
                spritesCopy[i] = sprites[i].clone();
            }
			// -- -- -- -- --
            var spritesCopy_2:Vector.<SpriteData> = new Vector.<SpriteData>();
            var length:uint = sprites_2.length;
            for (var i:uint = 0; i < length; i++) {
                spritesCopy_2[i] = sprites_2[i].clone();
            }
			// -- -- -- -- --
            var thingData:ThingData = new ThingData();
            thingData.thing = this.thing.clone();
            thingData.sprites = spritesCopy;
            thingData.sprites_2 = spritesCopy_2;
            return thingData;
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        private static const RECTANGLE:Rectangle = new Rectangle(0, 0, 32, 32);
        private static const POINT:Point = new Point();
        private static const COLOR_TRANSFORM:ColorTransform = new ColorTransform();
        private static const MATRIX_FILTER:ColorMatrixFilter = new ColorMatrixFilter([1, -1,    0, 0,
                                                                                      0, -1,    1, 0,
                                                                                      0,  0,    1, 1,
                                                                                      0,  0, -255, 0,
                                                                                      0, -1,    1, 0]);
        
		// aca
        public static function createThingData(thing:ThingType, sprites:Vector.<SpriteData>, sprites_2:Vector.<SpriteData> = null):ThingData
        {
            if (!thing) {
                throw new NullArgumentError("thing");
            }
            
            if (!sprites) {
                throw new NullArgumentError("sprites");
            }
            
            if (thing.spriteIndex.length != sprites.length) {
                throw new ArgumentError("Invalid sprites length.");
            }
            
            var thingData:ThingData = new ThingData();
            thingData.thing = thing;
            thingData.sprites = sprites;
			
			if(sprites_2) {
				if (thing.spriteIndex_2.length != sprites_2.length) {
					throw new ArgumentError("Invalid sprites_2 length.");
				}
				thingData.sprites_2 = sprites_2;
			}
            return thingData;
        }
        
        public static function createFromFile(file:File):ThingData
        {
            if (!file || file.extension != OTFormat.OBD || !file.exists)
                return null;
            
            var bytes:ByteArray = new ByteArray();
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            stream.readBytes(bytes, 0, stream.bytesAvailable);
            stream.close();
            return unserialize(bytes);
        }
        
        public static function serialize(data:ThingData, version:Version):ByteArray
        {
            if (!data) {
                throw new NullArgumentError("data");
            }
            
            if (!data) {
                throw new NullArgumentError("version");
            }
            
            var thing:ThingType = data.thing;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeShort(version.value); // Write client version
            bytes.writeUTF(thing.category);  // Write thing category
            
            var done:Boolean;
            if (version.value <= 730)
                done = ThingSerializer.writeProperties1(thing, bytes);
            else if (version.value <= 750)
                done = ThingSerializer.writeProperties2(thing, bytes);
            else if (version.value <= 772)
                done = ThingSerializer.writeProperties3(thing, bytes);
            else if (version.value <= 854)
                done = ThingSerializer.writeProperties4(thing, bytes);
            else if (version.value <= 986)
                done = ThingSerializer.writeProperties5(thing, bytes);
            else
                done = ThingSerializer.writeProperties6(thing, bytes);
            
            if (!done || !writeSprites(data, bytes)) return null;
            
            bytes.compress(CompressionAlgorithm.LZMA);
            return bytes;
        }
        
        public static function unserialize(bytes:ByteArray):ThingData
        {
            if (!bytes) {
                throw new NullArgumentError("bytes");
            }
            
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.uncompress(CompressionAlgorithm.LZMA);
            
			var v_ver:uint = bytes.readUnsignedShort();
            var version:Version = Versions.instance.getByValue( v_ver );
            if (!version)
                throw new Error("Unsupported version.");
            
            var thing:ThingType = new ThingType();
            thing.category = ThingCategory.getCategory( bytes.readUTF() );
            if (!thing.category) {
                throw new Error("Invalid thing category.");
            }
            
            var done:Boolean;
            if (version.value <= 730)
                done = ThingSerializer.readProperties1(thing, bytes);
            else if (version.value <= 750)
                done = ThingSerializer.readProperties2(thing, bytes);
            else if (version.value <= 772)
                done = ThingSerializer.readProperties3(thing, bytes);
            else if (version.value <= 854)
                done = ThingSerializer.readProperties4(thing, bytes);
            else if (version.value <= 986)
                done = ThingSerializer.readProperties5(thing, bytes);
            else
                done = ThingSerializer.readProperties6(thing, bytes);
            
            if (!done) return null;
			
			if (version.value >= 1057)	// apparently here is when they added the frame groups
				return readThingSprites(thing, bytes);
			else
				return readThingSprites_old(thing, bytes, false);
        }
        
        public static function getSpriteSheet(data:ThingData,
                                              textureIndex:Vector.<Rect> = null,
                                              backgroundColor:uint = 0xFFFF00FF):BitmapData
        {
            if (data == null) {
                throw new NullArgumentError("data");
            }
            
			var thing:ThingType = data.thing;
			var width:uint;
			var height:uint;
			var layers:uint;
			var patternX:uint;
			var patternY:uint;
			var patternZ:uint;
			var frames:uint;
			var size:uint = Sprite.SPRITE_PIXELS;
			var groups:uint = thing.groups;
			
			var totalX:int;
			var totalY:int;
			var bitmapWidth:Number;
			var bitmapHeight:Number;
			var pixelsWidth:int;
			var pixelsHeight:int;
			var bitmap:BitmapData;

			if (groups == 1) {
				width = thing.width;
				height = thing.height;
				layers = thing.layers;
				patternX = thing.patternX;
				patternY = thing.patternY;
				patternZ = thing.patternZ;
				frames = thing.frames;
				
				// -----< Measure and create bitmap>-----
				totalX = patternZ * patternX * layers;
				totalY = frames * patternY;
				bitmapWidth = (totalX * width) * size;
				bitmapHeight = (totalY * height) * size;
				pixelsWidth = width * size;
				pixelsHeight = height * size;
				bitmap = new BitmapData(bitmapWidth, bitmapHeight, true, backgroundColor);
				
				if (textureIndex) {
					textureIndex.length = layers * patternX * patternY * patternZ * frames;
				}
				
				for (var f:uint = 0; f < frames; f++) {
					for (var z:uint = 0; z < patternZ; z++) {
						for (var y:uint = 0; y < patternY; y++) {
							for (var x:uint = 0; x < patternX; x++) {
								for (var l:uint = 0; l < layers; l++) {
									
									var index:uint = getTextureIndex(thing, f, x, y, z, l);
									var fx:int = (index % totalX) * pixelsWidth;
									var fy:int = Math.floor(index / totalX) * pixelsHeight;
									
									if (textureIndex) {
										textureIndex[index] = new Rect(fx, fy, pixelsWidth, pixelsHeight);
									}
									
									for (var w:uint = 0; w < width; w++) {
										for (var h:uint = 0; h < height; h++) {
											index = getSpriteIndex(thing, w, h, l, x, y, z, f);
											var px:int = ((width - w - 1) * size);
											var py:int = ((height - h - 1) * size);
											copyPixels(data, index, bitmap, px + fx, py + fy);
										}
									}
								}
							}
						}
					}
				}
			} else {			
				width = thing.width;
				height = thing.height;
				layers = thing.layers;
				patternX = thing.patternX;
				patternY = thing.patternY;
				patternZ = thing.patternZ;
				frames = thing.frames;
				
				var width_2:uint = thing.width_2;
				var height_2:uint = thing.height_2;
				var layers_2:uint = thing.layers_2;
				var patternX_2:uint = thing.patternX_2;
				var patternY_2:uint = thing.patternY_2;
				var patternZ_2:uint = thing.patternZ_2;
				var frames_2:uint = thing.frames_2;
				
				var width_use:uint = ((width_2 > width) ? width_2 : width);
				var height_use:uint = ((height_2 > height) ? height_2 : height);
				
				// -----< Measure and create bitmap>-----
				totalX = patternZ * patternX * layers;
				totalY = frames * patternY;
				
				var totalX_2:int = patternZ_2 * patternX_2 * layers_2;
				var totalY_2:int = frames_2 * patternY_2;
				
				var totalX_use:int = ((totalX_2 > totalX) ? totalX_2 : totalX);
				var totalY_use:int = totalY + totalY_2;
				
				bitmapWidth = (totalX_use * width_use) * size;
				bitmapHeight = (totalY_use * height_use) * size;
				pixelsWidth = width_use * size;
				pixelsHeight = height_use * size;
				bitmap = new BitmapData(bitmapWidth, bitmapHeight, true, backgroundColor);
				
				if (textureIndex) {
					textureIndex.length = layers * patternX * patternY * patternZ * frames;
				}
				
				for (var g:uint = 0; g < groups; g++) {
					if (g == 0) {
						for (var f:uint = 0; f < frames; f++) {
							for (var z:uint = 0; z < patternZ; z++) {
								for (var y:uint = 0; y < patternY; y++) {
									for (var x:uint = 0; x < patternX; x++) {
										for (var l:uint = 0; l < layers; l++) {
											
											var index:uint = getTextureIndex(thing, f, x, y, z, l);
											var fx:int = (index % totalX_use) * pixelsWidth;
											var fy:int = Math.floor(index / totalX_use) * pixelsHeight;
											
											if (textureIndex) {
												textureIndex[index] = new Rect(fx, fy, pixelsWidth, pixelsHeight);
											}
									
											for (var w:uint = 0; w < width; w++) {
												for (var h:uint = 0; h < height; h++) {
													index = getSpriteIndex(thing, w, h, l, x, y, z, f);
													var px:int = ((width - w - 1) * size);
													var py:int = ((height - h - 1) * size);
													copyPixels(data, index, bitmap, px + fx, py + fy);
												}
											}
										}
									}
								}
							}
						}
					} else {
						for (var f:uint = 0; f < frames_2; f++) {
							for (var z:uint = 0; z < patternZ_2; z++) {
								for (var y:uint = 0; y < patternY_2; y++) {
									for (var x:uint = 0; x < patternX_2; x++) {
										for (var l:uint = 0; l < layers_2; l++) {
											
											var index:uint = getTextureIndex_2(thing, f, x, y, z, l);
											var fx:int = (index % totalX_use) * pixelsWidth;
											var fy:int = Math.floor(index / totalX_use) * pixelsHeight;
											fy += totalY * pixelsHeight;
											
											for (var w:uint = 0; w < width_2; w++) {
												for (var h:uint = 0; h < height_2; h++) {
													index = getSpriteIndex_2(thing, w, h, l, x, y, z, f);
													var px:int = ((width_2 - w - 1) * size);
													var py:int = ((height_2 - h - 1) * size);
													copyPixels_2(data, index, bitmap, px + fx, py + fy);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			return bitmap;
        }
        
        public static function setSpriteSheet(bitmap:BitmapData, thing:ThingType):ThingData
        {
            if (!bitmap) {
                throw new NullArgumentError("bitmap");
            }
            
            if (!thing) {
                throw new NullArgumentError("thing");
            }
            
            var rectSize:Rect = SpriteUtils.getSpriteSheetSize(thing);
            if (bitmap.width != rectSize.width || bitmap.height != rectSize.height) return null;
            
            bitmap = SpriteUtils.removeMagenta(bitmap);
            
            var width:uint = thing.width;
            var height: uint = thing.height;
            var layers:uint = thing.layers;
            var patternX:uint = thing.patternX;
            var patternY:uint = thing.patternY;
            var patternZ:uint = thing.patternZ;
            var frames:uint = thing.frames;
            var size:uint = Sprite.SPRITE_PIXELS;
            var totalX:int = patternZ * patternX * layers;
            var pixelsWidth:int  = width * size;
            var pixelsHeight:int = height * size;
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(width * height * layers * patternX * patternY * patternZ * frames);
            
            POINT.setTo(0, 0);
            
            for (var f:uint = 0; f < frames; f++) {
                for (var z:uint = 0; z < patternZ; z++) {
                    for (var y:uint = 0; y < patternY; y++) {
                        for (var x:uint = 0; x < patternX; x++) {
                            for (var l:uint = 0; l < layers; l++) {
                                
                                var index:uint = getTextureIndex(thing, f, x, y, z, l);
                                var fx:int = (index % totalX) * pixelsWidth;
                                var fy:int = Math.floor(index / totalX) * pixelsHeight;
                                
                                for (var w:uint = 0; w < width; w++) {
                                    for (var h:uint = 0; h < height; h++) {
                                        index = getSpriteIndex(thing, w, h, l, x, y, z, f);
                                        var px:int = ((width - w - 1) * size);
                                        var py:int = ((height - h - 1) * size);
                                        RECTANGLE.setTo(px + fx, py + fy, size, size);
                                        var bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
                                        bmp.copyPixels(bitmap, RECTANGLE, POINT);
                                        var spriteData:SpriteData = new SpriteData();
                                        spriteData.pixels = bmp.getPixels(bmp.rect);
                                        spriteData.id = uint.MAX_VALUE;
                                        sprites[index] = spriteData;
                                        thing.spriteIndex[index] = spriteData.id;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return createThingData(thing, sprites);
        }
        
        public static function colorizeSpriteSheet(thingData:ThingData,
                                                   head:uint = 0,
                                                   body:uint = 0,
                                                   legs:uint = 0,
                                                   feet:uint = 0,
                                                   addons:uint = 0):BitmapData
        {
            if (!thingData)
                return null;
            
            var textureRectList:Vector.<Rect> = new Vector.<Rect>();
            var spriteSheet:BitmapData = getSpriteSheet(thingData, textureRectList);
            spriteSheet = SpriteUtils.removeMagenta(spriteSheet);
            
            var thing:ThingType = thingData.thing;
            if (thing.layers != 2)
                return spriteSheet;
            
            var width:uint = thing.width;
            var height:uint = thing.height;
            var layers:uint = thing.layers;
            var patternX:uint = thing.patternX;
            var patternY:uint = thing.patternY;
            var patternZ:uint = thing.patternZ;
            var frames:uint = thing.frames;
            var size:uint = Sprite.SPRITE_PIXELS;
            var totalX:int = patternZ * patternX * layers;
            var totalY:int = height;
            var pixelsWidth:int  = width * size;
            var pixelsHeight:int = height * size;
            var bitmapWidth:uint = patternZ * patternX * pixelsWidth;
            var bitmapHeight:uint = frames * pixelsHeight;
            var numSprites:uint = layers * patternX * patternY * patternZ * frames;
            var grayBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var blendBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var colorBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var bitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var bitmapRect:Rectangle = bitmap.rect;
            var rectList:Vector.<Rect> = new Vector.<Rect>(numSprites, true);
            var index:uint;
            var f:uint;
            var x:uint;
            var y:uint;
            var z:uint;
            
            for (f = 0; f < frames; f++) {
                for (z = 0; z < patternZ; z++) {
                    for (x = 0; x < patternX; x++) {
                        index = (((f % frames * patternZ + z) * patternY + y) * patternX + x) * layers;
                        rectList[index] = new Rect((z * patternX + x) * pixelsWidth, f * pixelsHeight, pixelsWidth, pixelsHeight);
                    }
                }
            }
            
            for (y = 0; y < patternY; y++) {
                if (y == 0 || (addons & 1 << (y - 1)) != 0) {
                    for (f = 0; f < frames; f++) {
                        for (z = 0; z < patternZ; z++) {
                            for (x = 0; x < patternX; x++) {
                                var i:uint = (((f % frames * patternZ + z) * patternY + y) * patternX + x) * layers;
                                var rect:Rect = textureRectList[i];
                                RECTANGLE.setTo(rect.x, rect.y, rect.width, rect.height);
                                
                                index = (((f * patternZ + z) * patternY) * patternX + x) * layers;
                                rect = rectList[index];
                                POINT.setTo(rect.x, rect.y);
                                grayBitmap.copyPixels(spriteSheet, RECTANGLE, POINT);
                                
                                i++;
                                rect = textureRectList[i];
                                RECTANGLE.setTo(rect.x, rect.y, rect.width, rect.height);
                                blendBitmap.copyPixels(spriteSheet, RECTANGLE, POINT);
                            }
                        }
                    }
                    
                    POINT.setTo(0, 0);
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.BLUE, ColorUtils.HSItoARGB(feet));
                    blendBitmap.applyFilter(blendBitmap, bitmapRect, POINT, MATRIX_FILTER);
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.BLUE, ColorUtils.HSItoARGB(head));
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.RED, ColorUtils.HSItoARGB(body));
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.GREEN, ColorUtils.HSItoARGB(legs));
                    bitmap.copyPixels(grayBitmap, bitmapRect, POINT, null, null, true);
                }
            }
            
            grayBitmap.dispose();
            blendBitmap.dispose();
            colorBitmap.dispose();
            return bitmap;
        }
        
        public static function colorizeOutfit(outfit:ThingData,
                                              head:uint = 0,
                                              body:uint = 0,
                                              legs:uint = 0,
                                              feet:uint = 0,
                                              addons:uint = 0):ThingData
        {
            if (!outfit || outfit.category != ThingCategory.OUTFIT)
                return outfit;
            
            var spriteSheet:BitmapData = colorizeSpriteSheet(outfit, head, body, legs, feet, addons);
            var thing:ThingType = outfit.thing.clone();
            thing.patternY = 1;
            thing.layers = 1;
            thing.spriteIndex = ThingUtils.createSpriteIndexList(thing);
            return setSpriteSheet(spriteSheet, thing);
        }
        
        public static function setAlpha(thingData:ThingData, alpha:Number):ThingData
        {
            if (!thingData) return null;
            
            if (isNaN(alpha) || alpha < 0)
                alpha = 0;
            else if (alpha > 1)
                alpha = 1;
            
            var colorTransform:ColorTransform = new ColorTransform();
            colorTransform.alphaMultiplier = alpha;
            var bitmapData:BitmapData = getSpriteSheet(thingData, null, 0);
            bitmapData.colorTransform(bitmapData.rect, colorTransform);
            return setSpriteSheet(bitmapData, thingData.thing);
        }
        
        public static function getTextureIndex(thing:ThingType, f:int, x:int, y:int, z:int, l:int):int
        {
            return (((f % thing.frames * thing.patternZ + z) * thing.patternY + y) * thing.patternX + x) * thing.layers + l;
        }
		
        public static function getSpriteIndex(thing:ThingType, w:uint, h:uint, l:uint, x:uint, y:uint, z:uint, f:uint):uint
        {
            return ((((((f % thing.frames)
                * thing.patternZ + z)
                * thing.patternY + y)
                * thing.patternX + x)
                * thing.layers + l)
                * thing.height + h)
                * thing.width + w;
        }
        
		// -- -- -- -- -- 
        public static function getTextureIndex_2(thing:ThingType, f:int, x:int, y:int, z:int, l:int):int
        {
            return (((f % thing.frames_2 * thing.patternZ_2 + z) * thing.patternY_2 + y) * thing.patternX_2 + x) * thing.layers_2 + l;
        }
		
        public static function getSpriteIndex_2(thing:ThingType, w:uint, h:uint, l:uint, x:uint, y:uint, z:uint, f:uint):uint
        {
            return ((((((f % thing.frames_2)
                * thing.patternZ_2 + z)
                * thing.patternY_2 + y)
                * thing.patternX_2 + x)
                * thing.layers_2 + l)
                * thing.height_2 + h)
                * thing.width_2 + w;
        }
		// -- -- -- -- --
		
        private static function copyPixels(data:ThingData, index:uint, bitmap:BitmapData, x:uint, y:uint):void
        {
            if (index < data.length) {
                var spriteData:SpriteData = data.sprites[index];
                if (spriteData && spriteData.pixels) {
                    var bmp:BitmapData = spriteData.getBitmap();
                    if (bmp) {
                        spriteData.pixels.position = 0;
                        RECTANGLE.setTo(0, 0, bmp.width, bmp.height);
                        POINT.setTo(x, y);
                        bitmap.copyPixels(bmp, RECTANGLE, POINT, null, null, true);
                    }
                }
            }
        }
        
        private static function copyPixels_2(data:ThingData, index:uint, bitmap:BitmapData, x:uint, y:uint):void
        {
            if (index < data.length_2) {
                var spriteData:SpriteData = data.sprites_2[index];
                if (spriteData && spriteData.pixels) {
                    var bmp:BitmapData = spriteData.getBitmap();
                    if (bmp) {
                        spriteData.pixels.position = 0;
                        RECTANGLE.setTo(0, 0, bmp.width, bmp.height);
                        POINT.setTo(x, y);
                        bitmap.copyPixels(bmp, RECTANGLE, POINT, null, null, true);
                    }
                }
            }
        }

        private static function writeSprites(data:ThingData, bytes:ByteArray):Boolean
        {
			var thing:ThingType = data.thing;
			// -- -- --
			var writeFrameDuration:Boolean = true;
			var useGroups:Boolean = true;
			// jano edit
			var hasGroups:Boolean = (useGroups && (thing.category == ThingCategory.OUTFIT));
			if(hasGroups) {
				bytes.writeByte(thing.groups);
			}
            // end jano

			var group:uint;
			for(group = 0; group < thing.groups; group++) 
			{
				if(hasGroups) {
					bytes.writeByte(group);	// does it matter??
				}
					
				if(group == 0) {
					bytes.writeByte(thing.width);  // Write width
					bytes.writeByte(thing.height); // Write height
					
					if (thing.width > 1 || thing.height > 1) {
						bytes.writeByte(thing.exactSize); // Write exact size
					}
					
					bytes.writeByte(thing.layers);   // Write layers
					bytes.writeByte(thing.patternX); // Write pattern X
					bytes.writeByte(thing.patternY); // Write pattern Y
					bytes.writeByte(thing.patternZ); // Write pattern Z
					bytes.writeByte(thing.frames);   // Write frames
					
					if (thing.isAnimation && writeFrameDuration) {
						bytes.writeByte(thing.animationMode);   // Write animation type
						bytes.writeInt(thing.frameStrategy);    // Write frame strategy
						bytes.writeByte(thing.startFrame);      // Write start frame
						
						var frameDurations:Vector.<FrameDuration> = thing.frameDurations;
						var length:uint = frameDurations.length;
						
						for (i = 0; i < length; i++) {
							bytes.writeUnsignedInt(frameDurations[i].minimum); // Write minimum duration
							bytes.writeUnsignedInt(frameDurations[i].maximum); // Write maximum duration
						}
					}
					
					var spriteList:Vector.<uint> = thing.spriteIndex;
					var length:uint = spriteList.length;
					for (var i:uint = 0; i < length; i++) {
						var spriteId:uint = spriteList[i];
						var spriteData:SpriteData = data.sprites[i];
						if (!spriteData || !spriteData.pixels) {
							throw new Error(StringUtil.substitute("Invalid sprite id.", spriteId));
						}
						
						var pixels:ByteArray = spriteData.pixels;
						pixels.position = 0;
						bytes.writeUnsignedInt(spriteId);
						bytes.writeUnsignedInt(pixels.length);
						bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
					}
					// -- -- -- -- -- --
				} else {
					bytes.writeByte(thing.width_2);  // Write width
					bytes.writeByte(thing.height_2); // Write height
					
					if (thing.width_2 > 1 || thing.height_2 > 1) {
						bytes.writeByte(thing.exactSize_2); // Write exact size
					}
					
					bytes.writeByte(thing.layers_2);   // Write layers
					bytes.writeByte(thing.patternX_2); // Write pattern X
					bytes.writeByte(thing.patternY_2); // Write pattern Y
					bytes.writeByte(thing.patternZ_2); // Write pattern Z
					bytes.writeByte(thing.frames_2);   // Write frames
					
					if (thing.isAnimation_2 && writeFrameDuration) {
						bytes.writeByte(thing.animationMode_2);   // Write animation type
						bytes.writeInt(thing.frameStrategy_2);    // Write frame strategy
						bytes.writeByte(thing.startFrame_2);      // Write start frame
						
						var frameDurations:Vector.<FrameDuration> = thing.frameDurations_2;
						var length:uint = frameDurations.length;
						
						for (i = 0; i < length; i++) {
							bytes.writeUnsignedInt(frameDurations[i].minimum); // Write minimum duration
							bytes.writeUnsignedInt(frameDurations[i].maximum); // Write maximum duration
						}
					}
					
					var spriteList:Vector.<uint> = thing.spriteIndex_2;
					var length:uint = spriteList.length;
					
					for (var i:uint = 0; i < length; i++) {
						var spriteId:uint = spriteList[i];
						var spriteData:SpriteData = data.sprites_2[i];
						if (!spriteData || !spriteData.pixels) {
							throw new Error(StringUtil.substitute("Invalid sprite id.", spriteId));
						}
						
						var pixels:ByteArray = spriteData.pixels;
						pixels.position = 0;
						bytes.writeUnsignedInt(spriteId);
						bytes.writeUnsignedInt(pixels.length);
						bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
					}
					// -- -- -- -- -- --
				}
			}			
            return true;
        }
		
        private static function readThingSprites(thing:ThingType, bytes:ByteArray):ThingData
        {
			
			// -- -- -- -- -- -- --
			var readFrameDuration:Boolean = true;
			var useGroups:Boolean = true;
			// jano edit
			var hasGroups:Boolean = (useGroups && (thing.category == ThingCategory.OUTFIT));
			var groups:uint = hasGroups ? bytes.readUnsignedByte() : 1;
			
			thing.hasGroups = hasGroups;
			thing.groups = groups;
            // end jano
            
			// -- -- -- --
			var sprites:Vector.<SpriteData>;
			var sprites_2:Vector.<SpriteData>;
			// -- -- -- --

			var group:uint;
			for(group = 0; group < groups; group++) {
				if(hasGroups) {
					bytes.readUnsignedByte();
				}
					
				if(group == 0) {
					thing.width  = bytes.readUnsignedByte();
					thing.height = bytes.readUnsignedByte();
					
					if (thing.width > 1 || thing.height > 1)
						thing.exactSize = bytes.readUnsignedByte();
					else 
						thing.exactSize = Sprite.SPRITE_PIXELS;
					
					thing.layers = bytes.readUnsignedByte();
					thing.patternX = bytes.readUnsignedByte();
					thing.patternY = bytes.readUnsignedByte();
					thing.patternZ = bytes.readUnsignedByte();
					thing.frames = bytes.readUnsignedByte();
					
					thing.frameDurations = new Vector.<FrameDuration>(); // here to avoid crash
					thing.frameDurations_2 = new Vector.<FrameDuration>(); // here to avoid crash
					if (thing.frames > 1) {
						thing.isAnimation = true;
						
						var animationMode:uint = 0;		// AnimationMode.ASYNCHRONOUS
						var frameStrategy:int = 0;		// FrameStrategyType.LOOP
						var startFrame:int = -1;
						var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
					
						if (readFrameDuration) {
							animationMode = bytes.readUnsignedByte();
							frameStrategy = bytes.readInt();
							startFrame = bytes.readByte();
							
							for (i = 0; i < thing.frames; i++)
							{
								var minimum:uint = bytes.readUnsignedInt();
								var maximum:uint = bytes.readUnsignedInt();
								frameDurations[i] = new FrameDuration(minimum, maximum);
							}
						} else {
							var duration:uint = FrameDuration.getDefaultDuration(thing.category);
							for (i = 0; i < thing.frames; i++)
								frameDurations[i] = new FrameDuration(duration, duration);
						}
						
						thing.animationMode = animationMode;
						thing.frameStrategy = frameStrategy;
						thing.startFrame = startFrame;		
						thing.frameDurations = frameDurations;
					}
						
					var totalSprites:uint = thing.width * thing.height * thing.layers * thing.patternX * thing.patternY * thing.patternZ * thing.frames;
					if (totalSprites > 4096) {
						throw new Error("Thing has more than 4096 sprites.");
					}
					
					thing.spriteIndex = new Vector.<uint>(totalSprites);
					sprites = new Vector.<SpriteData>(totalSprites);
					
					for (var i:uint = 0; i < totalSprites; i++) {
						var spriteId:uint = bytes.readUnsignedInt();
						var length:uint = bytes.readUnsignedInt();
						if (length > bytes.bytesAvailable) {
							throw new Error("Not enough data.");
						}
						
						thing.spriteIndex[i] = spriteId;
						var pixels:ByteArray = new ByteArray();
						pixels.endian = Endian.BIG_ENDIAN;
						bytes.readBytes(pixels, 0, length);
						pixels.position = 0;
						var spriteData:SpriteData = new SpriteData();
						spriteData.id = spriteId;
						spriteData.pixels = pixels;
						sprites[i] = spriteData;
					}					
				} else {
					thing.width_2  = bytes.readUnsignedByte();
					thing.height_2 = bytes.readUnsignedByte();
					
					if (thing.width_2 > 1 || thing.height_2 > 1)
						thing.exactSize_2 = bytes.readUnsignedByte();
					else 
						thing.exactSize_2 = Sprite.SPRITE_PIXELS;
					
					thing.layers_2 = bytes.readUnsignedByte();
					thing.patternX_2 = bytes.readUnsignedByte();
					thing.patternY_2 = bytes.readUnsignedByte();
					thing.patternZ_2 = bytes.readUnsignedByte();
					thing.frames_2 = bytes.readUnsignedByte();
					
					if (thing.frames_2 > 1) {
						thing.isAnimation_2 = true;
						
						var animationMode:uint = 0;		// AnimationMode.ASYNCHRONOUS
						var frameStrategy:int = 0;		// FrameStrategyType.LOOP
						var startFrame:int = -1;
						var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames_2, true);
					
						if (readFrameDuration) {
							animationMode = bytes.readUnsignedByte();
							frameStrategy = bytes.readInt();
							startFrame = bytes.readByte();
							
							for (i = 0; i < thing.frames_2; i++)
							{
								var minimum:uint = bytes.readUnsignedInt();
								var maximum:uint = bytes.readUnsignedInt();
								frameDurations[i] = new FrameDuration(minimum, maximum);
							}
						} else {
							var duration:uint = FrameDuration.getDefaultDuration(thing.category);
							for (i = 0; i < thing.frames_2; i++)
								frameDurations[i] = new FrameDuration(duration, duration);
						}
						
						thing.animationMode_2 = animationMode;
						thing.frameStrategy_2 = frameStrategy;
						thing.startFrame_2 = startFrame;		
						thing.frameDurations_2 = frameDurations;
					}
						
					var totalSprites:uint = thing.width_2 * thing.height_2 * thing.layers_2 * thing.patternX_2 * thing.patternY_2 * thing.patternZ_2 * thing.frames_2;
					if (totalSprites > 4096) {
						throw new Error("Thing has more than 4096 sprites.");
					}
					
					thing.spriteIndex_2 = new Vector.<uint>(totalSprites);
					sprites_2 = new Vector.<SpriteData>(totalSprites);
					
					for (var i:uint = 0; i < totalSprites; i++) {
						var spriteId:uint = bytes.readUnsignedInt();
						var length:uint = bytes.readUnsignedInt();
						if (length > bytes.bytesAvailable) {
							throw new Error("Not enough data.");
						}
						
						thing.spriteIndex_2[i] = spriteId;
						var pixels:ByteArray = new ByteArray();
						pixels.endian = Endian.BIG_ENDIAN;
						bytes.readBytes(pixels, 0, length);
						pixels.position = 0;
						var spriteData:SpriteData = new SpriteData();
						spriteData.id = spriteId;
						spriteData.pixels = pixels;
						sprites_2[i] = spriteData;
					}
				}
			}
            return createThingData(thing, sprites, sprites_2);
        }
        
        private static function readThingSprites_old(thing:ThingType, bytes:ByteArray, readFrameDuration:Boolean = false):ThingData
        {
			// will attemp to auto calculate if is outfit
			// it might need manual fix
			var canHaveGroups:Boolean = ((thing.category == ThingCategory.OUTFIT) && !thing.animateAlways);
			var sprites:Vector.<SpriteData>;

			thing.width  = bytes.readUnsignedByte();
			thing.height = bytes.readUnsignedByte();
			
			if (thing.width > 1 || thing.height > 1)
				thing.exactSize = bytes.readUnsignedByte();
			else 
				thing.exactSize = Sprite.SPRITE_PIXELS;
			
			thing.layers = bytes.readUnsignedByte();
			thing.patternX = bytes.readUnsignedByte();
			thing.patternY = bytes.readUnsignedByte();
			thing.patternZ = bytes.readUnsignedByte();
			thing.frames = bytes.readUnsignedByte();
			
			thing.frameDurations = new Vector.<FrameDuration>(); // here to avoid crash
			
			if (thing.frames > 1) {
				thing.isAnimation = true;
				
				var animationMode:uint = 0;		// AnimationMode.ASYNCHRONOUS
				var frameStrategy:int = 0;		// FrameStrategyType.LOOP
				var startFrame:int = -1;
				var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
			
				if (readFrameDuration) {
					animationMode = bytes.readUnsignedByte();
					frameStrategy = bytes.readInt();
					startFrame = bytes.readByte();
					
					for (i = 0; i < thing.frames; i++)
					{
						var minimum:uint = bytes.readUnsignedInt();
						var maximum:uint = bytes.readUnsignedInt();
						frameDurations[i] = new FrameDuration(minimum, maximum);
					}
				} else {
					var duration:uint = FrameDuration.getDefaultDuration(thing.category);
					for (i = 0; i < thing.frames; i++)
						frameDurations[i] = new FrameDuration(duration, duration);
				}
				
				thing.animationMode = animationMode;
				thing.frameStrategy = frameStrategy;
				thing.startFrame = startFrame;		
				thing.frameDurations = frameDurations;
			}
				
			var totalSprites:uint = thing.width * thing.height * thing.layers * thing.patternX * thing.patternY * thing.patternZ * thing.frames;
			if (totalSprites > 4096) {
				throw new Error("Thing has more than 4096 sprites.");
			}
			
			thing.spriteIndex = new Vector.<uint>(totalSprites);
			sprites = new Vector.<SpriteData>(totalSprites);
			
			for (var i:uint = 0; i < totalSprites; i++) {
				var spriteId:uint = bytes.readUnsignedInt();
				var length:uint = bytes.readUnsignedInt();
				if (length > bytes.bytesAvailable) {
					throw new Error("Not enough data.");
				}
				
				thing.spriteIndex[i] = spriteId;
				var pixels:ByteArray = new ByteArray();
				pixels.endian = Endian.BIG_ENDIAN;
				bytes.readBytes(pixels, 0, length);
				pixels.position = 0;
				var spriteData:SpriteData = new SpriteData();
				spriteData.id = spriteId;
				spriteData.pixels = pixels;
				sprites[i] = spriteData;
			}					

			// -- -- -- -- -- --
			var sprites_2:Vector.<SpriteData>;
			var hasGroups:Boolean = false;
			var groups:uint = 1;
			if(canHaveGroups && thing.frames > 1) {
				hasGroups = true;
				groups = 2;
				
				// init attributes
				thing.width_2  = thing.width;
				thing.height_2 = thing.height;
				thing.exactSize_2 = thing.exactSize;
				thing.layers_2 = thing.layers;
				thing.patternX_2 = thing.patternX;
				thing.patternY_2 = thing.patternY;
				thing.patternZ_2 = thing.patternZ;
			
				// split frames
				var originalFrames:uint = thing.frames;
				thing.frames = 1;
				thing.frames_2 = originalFrames - 1;
				
				// make groups
				thing.isAnimation = false;
				thing.isAnimation_2 = (thing.frames_2 > 1);
				
				thing.frameDurations_2 = new Vector.<FrameDuration>(); // here to avoid crash
				if(thing.isAnimation_2) {
					thing.animationMode = thing.animationMode;
					thing.frameStrategy = thing.frameStrategy;
					thing.startFrame = thing.startFrame;
					
					var nfd:Vector.<FrameDuration> = new Vector.<FrameDuration>();
					for(var fd = 1; fd < originalFrames; fd++) {
						nfd[fd - 1] = thing.frameDurations[fd];
					}
					thing.frameDurations_2 = nfd;
				}
				
				// doesn't really matter at this point but whatever
				thing.animationMode = null;
				thing.frameStrategy = null;
				thing.startFrame = null;		
				thing.frameDurations = null;
			
				// recalculate sprites and indexes
				// idle / standing group
				totalSprites = thing.width * thing.height * thing.layers * thing.patternX * thing.patternY * thing.patternZ;

				var tmp_sprin:Vector.<uint> = new Vector.<uint>(totalSprites);
				var tmp_spr:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites);
				
				for (var i:uint = 0; i < totalSprites; i++) {
					tmp_sprin[i] = thing.spriteIndex[i];
					tmp_spr[i] = sprites[i];
				}
				
				var orig_sprin:Vector.<uint> = thing.spriteIndex;
				var orig_spr:Vector.<SpriteData> = sprites;
				
				thing.spriteIndex = tmp_sprin;
				sprites = tmp_spr;
				
				// -- -- -- -- --
				// walking group
				var toadd:uint = totalSprites;
				totalSprites = thing.width_2 * thing.height_2 * thing.layers_2 * thing.patternX_2 * thing.patternY_2 * thing.patternZ_2 * thing.frames_2;

				// recalculate sprites and indexes
				tmp_sprin = new Vector.<uint>(totalSprites);
				tmp_spr = new Vector.<SpriteData>(totalSprites);
				
				for (var i:uint = 0; i < totalSprites; i++) {
					tmp_sprin[i] = orig_sprin[i + toadd];
					tmp_spr[i] = orig_spr[i + toadd];
				}
				
				thing.spriteIndex_2 = tmp_sprin;
				sprites_2 = tmp_spr;
			}
			// -- -- -- -- -- --
			thing.hasGroups = hasGroups;
			thing.groups = groups;
			// -- -- -- --
            return createThingData(thing, sprites, sprites_2);
        }
        
        private static function setColor(canvas:BitmapData,
                                         grey:BitmapData,
                                         blend:BitmapData,
                                         rect:Rectangle,
                                         channel:uint,
                                         color:uint):void
        {
            POINT.setTo(0, 0);
            COLOR_TRANSFORM.redMultiplier = (color >> 16 & 0xFF) / 0xFF;
            COLOR_TRANSFORM.greenMultiplier = (color >> 8 & 0xFF) / 0xFF;
            COLOR_TRANSFORM.blueMultiplier = (color & 0xFF) / 0xFF;
            
            canvas.copyPixels(grey, rect, POINT);
            canvas.copyChannel(blend, rect, POINT, channel, BitmapDataChannel.ALPHA);
            canvas.colorTransform(rect, COLOR_TRANSFORM);
            grey.copyPixels(canvas, rect, POINT, null, null, true);
        }
    }
}
