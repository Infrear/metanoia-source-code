-- Summon VFX module. Called once when a persona begins its summon sequence (same moment the
-- base/crest mesh FX starts growing), so it can layer in extra effects (particles, sounds, light
-- flashes, etc.) on top.
--
-- Params:
--   spawnCFrame  : CFrame  -- where the persona is materializing (already offset per-persona via
--                            PersonaSpawnVFXOffset)
--   personaModel : Model   -- the persona's own rig (currently hidden/tiny while the mesh FX plays;
--                            do not rely on its Size mid-effect, it's driven separately)
--   targetSize   : Vector3 -- the persona's real, full-scale extents (use for scaling any effect parts)
--   growDuration : number  -- seconds the base/crest mesh FX takes to grow to full size, for timing
--                            this effect to land in sync
return function(spawnCFrame, personaModel, targetSize, growDuration)
	print("vfx one spawned")
end
