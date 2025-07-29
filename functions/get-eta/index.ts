import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

// Load environment variables
const googleMapsApiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')

serve(async (req) => {
  try {
    const { origin, destination } = await req.json()

    if (!googleMapsApiKey) {
      throw new Error('Google Maps API key is not set.')
    }

    if (!origin || !destination) {
      throw new Error('Origin or destination is missing.')
    }

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin.lat},${origin.lng}&destination=${destination.lat},${destination.lng}&key=${googleMapsApiKey}&language=ar`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.status !== 'OK') {
      throw new Error(`Directions API failed with status: ${data.status}`);
    }

    const leg = data.routes[0].legs[0];
    const eta = {
      distance: leg.distance.text,
      duration: leg.duration.text,
    };

    return new Response(
      JSON.stringify(eta),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
