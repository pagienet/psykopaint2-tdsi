package net.psykosoft.psykopaint2.tdsi
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import apparat.asm.DecLocalInt;
	import apparat.asm.IncLocalInt;
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.memory.Memory;
	

	public class PyramidMapTdsi
	{
		private var _offsets:Vector.<int>;
		//private var _offsets:Vector.<Matrix>;
		
		private var _data:ByteArray;
		private var width:int;
		private var height:int;
		
		private const ilog2:Number = 1 / Math.log(2);
		private const i255:Number = 1 / 255;
		private var _baseOffset:int;

		
		
		public function PyramidMapTdsi( sourceMap:BitmapData )
		{
			setSource( sourceMap );
		}

		public function dispose() : void
		{
			//if ( _data ) _data.length = 0;
		}
		/*
		public function setSource( map:BitmapData ):void
		{
			width = map.width;
			height = map.height;
			
			var w:int = width;
			var h:int = height;
			
			//var levels:int = 1 + Math.log(Math.min(width,height)) * ilog2;
			_offsets = new Vector.<int>();
			var o:int = w*h*4;
			var levels:int = 0;
			while ( w > 0 && h > 0 )
			{
				_offsets[levels++] = o;
				w >>= 1;
				h >>= 1;
				o += __cint(w*h*4);
			}
			
			_data = new ByteArray();
			_data.endian = Endian.LITTLE_ENDIAN;
			
			_data.length =  width * height * 8;
			
			activateMemory();
			
			_data.position = 0;
			_data.writeBytes( map.getPixels(map.rect) );
			var mask1:int = 0xff00ff;
			var mask2:int = 0x00ff00;
			
			w = width;
			h = height;
			var ww:int = w;
			var hh:int = h;
			var i:int = 0;
			var j:int = width * height * 4;
			while ( levels > 0 )
			{
				var v1:int = Memory.readInt(i) >>> 8;
				var v2:int = Memory.readInt(__cint(i+1)) >>> 8;
				v1 = ((( v1 & mask1) + ( v2 & mask1 )) >> 1) | ((( v1 & mask2) + ( v2 & mask2 )) >> 1)
				v2 = Memory.readInt(__cint(i+w)) >>> 8;
				var v3:int = Memory.readInt(__cint(i+1+w)) >>> 8;
				v2 = ((( v2 & mask1) + ( v3 & mask1 )) >> 1) | ((( v2 & mask2) + ( v3 & mask2 )) >> 1)
				v1 = ((( v1 & mask1) + ( v2 & mask1 )) >> 1) | ((( v1 & mask2) + ( v2 & mask2 )) >> 1)
				Memory.writeInt( v1, j );		
				__asm( 
					IncLocalInt(i),
					IncLocalInt(i),
					IncLocalInt(j),
					DecLocalInt(ww)
					);
				if ( ww == 0 ) 
				{
					i = __cint( i+w);
					__asm( 
						DecLocalInt(hh)
					);	
					if ( hh == 0 )
					{
						w >>= 1;
						h >>= 1;
						hh = h;
						__asm( 
							DecLocalInt(levels)
						);	
					}
					ww = w;
				}
			}
			
			
		}
		*/
		
		public function setSource( map:BitmapData ):void
		{
			width = map.width;
			height = map.height;
			
			var _scaled:BitmapData = new BitmapData(Math.ceil(width * 0.75), Math.ceil(height * 0.5), true, 0 );
			var m:Matrix = new Matrix(0.5,0,0,0.5);
			_scaled.draw( map, m, null, "normal",null,true);
			m.tx += width * 0.5;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			m.ty += height * 0.25;
			m.a = m.d *= 0.5;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			m.a = m.d *= 0.25;
			m.tx += width * 0.125;
			m.ty += height * 0.0625;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			
			var f:Number = 1;
			var r:Vector.<Rectangle> = new Vector.<Rectangle>();
			var rect:Rectangle = new Rectangle(0,0,width*0.5,height*0.5);
			r.push(rect.clone());
			
			_offsets = new Vector.<int>();
			var offset:int =  width*height*4;
			_offsets.push( offset);
			
			
			for ( var i:int = 0; i < 6; i++ )
			{
				rect.width >>= 1;
				rect.height >>= 1;
				if ( rect.width == 0 || rect.height == 0 ) break;
				rect.x += width * (f *= 0.5);
				r.push(rect.clone());
				offset += rect.width * rect.height * 4; 
				_offsets.push(offset);
			
				rect.width  >>= 1;
				rect.height >>= 1;
				if ( rect.width == 0 || rect.height == 0 ) break;
				rect.y += height * (f *= 0.5);
				r.push(rect.clone());
				offset += rect.width * rect.height * 4; 
				_offsets.push(offset);
				
			}
			
			_baseOffset = MemoryManagerTdsi.reserveMemory( width * height * 4 + offset);
			_data = MemoryManagerTdsi.memory;
			
			_data.position = _baseOffset;
			_data.writeBytes( map.getPixels(map.rect) );
			for ( i = 0; i < r.length; i++ )
			{
				_offsets[i] += _baseOffset;
				_data.writeBytes( _scaled.getPixels(r[i]) );
			}
			_scaled.dispose();
			
		}
		
		public function getRGB( x:Number, y:Number, radius:Number, target:Vector.<Number>, slotOffset:int, colorBlendFactor:Number ):void
		{
			
			var xx:int = x + 0.5;
			var yy:int = y +0.5;
			
			
			if ( xx < 0 ) xx = 0;
			else if ( xx >= width ) xx = __cint(width - 1);
			if ( yy < 0 )yy = 0;
			else if ( yy >= height ) yy =__cint(height - 1);
			
			var offset:int = _baseOffset + ((xx + yy * width) << 2 );
			if (true || radius <= 1 )
			{
				var c:uint = Memory.readInt(offset);
				target[slotOffset] += ((( c >>> 8 ) & 0xff) * i255 - target[slotOffset] ) * colorBlendFactor;
				target[__cint(slotOffset+1)] += ((( c >>> 16 ) & 0xff) * i255 - target[__cint(slotOffset+1)] ) * colorBlendFactor;
				target[__cint(slotOffset+2)] += ((( c >>> 24 ) & 0xff) * i255 - target[__cint(slotOffset+2)] ) * colorBlendFactor;;
				target[__cint(slotOffset+3)] = 1;
				return;
			}
			//TODO: this part is temporary disabled until i found the bug
			
			var index:int = -1;
			var stride:int = width;
			var scaledRadius:int = radius+0.5;
			while ( scaledRadius > 1 && index < _offsets.length - 1)
			{
				scaledRadius >>= 1;
				index++;
				xx >>= 1;
				yy >>= 1;
				stride >>= 1;
			}
			
			if ( index >= 0 )
			{
				var v1:uint = Memory.readInt( __cint(_offsets[index] + ((xx + yy * stride) << 2) ));
			} else {
				v1 = Memory.readInt(offset);
			}
			
			xx >>= 1;
			yy >>= 1;
			stride >>= 1;
			
			var v2:uint = Memory.readInt( __cint(_offsets[index+1] + ((xx + yy * stride) << 2)));
			
			//var f:Number = 2 - Math.pow(2, radius / Math.pow(2,index) - 1 );
			var f:Number = 0.5 * ( 4 - Math.pow(2,radius * Math.pow(2,-index)) );
			
			var r1:Number = ((v1 >>> 8) & 0xff);
			var g1:Number = ((v1 >>> 16) & 0xff);
			var b1:Number = ((v1 >>> 24) & 0xff);
			
			var r2:Number = ((v2 >>> 8) & 0xff);
			var g2:Number = ((v2 >>> 16) & 0xff);
			var b2:Number = ((v2 >>> 24) & 0xff);
			
			target[slotOffset]  += ((r2 + ( r1 - r2 ) * f) * i255 - target[slotOffset] ) * colorBlendFactor;
			target[__cint(slotOffset+1)] += ((g2 + ( g1 - g2 ) * f) * i255 - target[__cint(slotOffset+1)] ) * colorBlendFactor;
			target[__cint(slotOffset+2)] += ((b2 + ( b1 - b2 ) * f) * i255 - target[__cint(slotOffset+2)] ) * colorBlendFactor;
			target[__cint(slotOffset+3)] = 1;
		}
		
	}
}