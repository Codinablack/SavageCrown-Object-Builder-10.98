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

package nail.otlib.utils
{
    import flash.utils.describeType;
    
    import nail.errors.AbstractClassError;
    import nail.otlib.things.ThingCategory;
    import nail.otlib.things.ThingType;
    import nail.resources.Resources;
	import nail.otlib.things.FrameDuration;
    
    public final class ThingUtils
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingUtils()
        {
            throw new AbstractClassError(ThingUtils);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static function copyThing(thing:ThingType):ThingType
        {
            if (!thing) return null;
            
            var newThing:ThingType = new ThingType();
            var description:XMLList = describeType(thing)..variable;
            for each (var property:XML in description) {
                var name:String = property.@name;
                newThing[name] = thing[name];
            }
            
            if (thing.spriteIndex) {
                newThing.spriteIndex = thing.spriteIndex.concat();
            }
			
            if (thing.spriteIndex_2) {
                newThing.spriteIndex_2 = thing.spriteIndex_2.concat();
            }
			
            if (thing.frameDurations) {
                newThing.frameDurations = thing.frameDurations.concat();
            }
			
            if (thing.frameDurations_2) {
                newThing.frameDurations_2 = thing.frameDurations_2.concat();
            }
            return newThing;
        }
        
        public static function createThing(category:String, id:uint = 0):ThingType
        {
            if (!ThingCategory.getCategory(category)) {
                throw new Error(Resources.getString("strings", "invalidCategory"));
            }
            
            var thing:ThingType = new ThingType();
            thing.category = category;
            thing.id = id;
			
			if (thing.category == ThingCategory.OUTFIT) {
				thing.hasGroups = true;
				thing.groups = 2;
			} else {
				thing.hasGroups = false;
				thing.groups = 1;
			}
			
            thing.width = 1;
            thing.height = 1;
            thing.layers = 1;
            thing.frames = 1;
            thing.patternX = 1;
            thing.patternY = 1;
            thing.patternZ = 1;
            thing.exactSize = 32;
			
			// -- -- -- -- -- --
            thing.width_2 = 1;
            thing.height_2 = 1;
            thing.layers_2 = 1;
            thing.frames_2 = 1;
            thing.patternX_2 = 1;
            thing.patternY_2 = 1;
            thing.patternZ_2 = 1;
            thing.exactSize_2 = 32;
            // -- -- -- -- -- --
			
            switch(category) {
                case ThingCategory.OUTFIT:
                    thing.patternX = 4;
                    thing.frames = 3;
					// -- -- -- -- -- --
					thing.patternX_2 = 4;
                    thing.frames_2 = 3;
					// -- -- -- -- -- --
                    break;
                case ThingCategory.MISSILE:
                    thing.patternX = 3;
                    thing.patternY = 3;
                    break;
            }
            
            thing.spriteIndex = createSpriteIndexList(thing);
			thing.spriteIndex_2 = createSpriteIndexList_2(thing);
  
			thing.frameDurations = new Vector.<FrameDuration>(); // here to avoid crash
			thing.frameDurations_2 = new Vector.<FrameDuration>(); // here to avoid crash
				
			createDefaultFrameDurations(thing);
			createDefaultFrameDurations_2(thing);

            return thing;
        }
        
        public static function createAlertThing(category:String):ThingType
        {
            var thing:ThingType = createThing(category);
            if (thing) {
                var spriteIndex:Vector.<uint> = thing.spriteIndex;
                var length:uint = spriteIndex.length;
                for (var i:uint = 0; i < length; i++) {
                    spriteIndex[i] = 0xFFFFFFFF;
                }
            }
            return thing;
        }
        
        public static function isValid(thing:ThingType):Boolean
        {
            if (thing && thing.width != 0 && thing.height != 0) return true;
            return false;
        }
        
        public static function createSpriteIndexList(thing:ThingType):Vector.<uint>
        {
            if (thing)
                return new Vector.<uint>(thing.width *
                                         thing.height *
                                         thing.patternX *
                                         thing.patternY *
                                         thing.patternZ *
                                         thing.layers *
                                         thing.frames);
            return null;
        }
		
        public static function createSpriteIndexList_2(thing:ThingType):Vector.<uint>
        {
            if (thing)
                return new Vector.<uint>(thing.width_2 *
                                         thing.height_2 *
                                         thing.patternX_2 *
                                         thing.patternY_2 *
                                         thing.patternZ_2 *
                                         thing.layers_2 *
                                         thing.frames_2);
            return null;
        }
		
		public static function createDefaultFrameDurations(thing:ThingType):void
		{
            if (thing) {
				if (thing.frames > 1) {
					thing.isAnimation = true;
					
					var animationMode:uint = 0;		// AnimationMode.ASYNCHRONOUS
					var frameStrategy:int = 0;		// FrameStrategyType.LOOP
					var startFrame:int = -1;
					var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
				
					var i:uint;
					var duration:uint = FrameDuration.getDefaultDuration(thing.category);
					for (i = 0; i < thing.frames; i++)
						frameDurations[i] = new FrameDuration(duration, duration);
					
					thing.animationMode = animationMode;
					thing.frameStrategy = frameStrategy;
					thing.startFrame = startFrame;							
					thing.frameDurations = frameDurations;
				}
			}
		}
		
		public static function createDefaultFrameDurations_2(thing:ThingType):void
		{
            if (thing) {
				if (thing.frames_2 > 1) {
					thing.isAnimation_2 = true;
					
					var animationMode:uint = 0;		// AnimationMode.ASYNCHRONOUS
					var frameStrategy:int = 0;		// FrameStrategyType.LOOP
					var startFrame:int = -1;
					var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames_2, true);
				
					var i:uint;
					var duration:uint = FrameDuration.getDefaultDuration(thing.category);
					for (i = 0; i < thing.frames_2; i++)
						frameDurations[i] = new FrameDuration(duration, duration);
					
					thing.animationMode_2 = animationMode;
					thing.frameStrategy_2 = frameStrategy;
					thing.startFrame_2 = startFrame;							
					thing.frameDurations_2 = frameDurations;
				}
			}
		}
    }
}
