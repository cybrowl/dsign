<script>
	export let name;
	export let width = '1rem';
	export let height = '1rem';
	export let focusable = false;

	let icons = {
		close_standard: {
			box: 20,
			name: 'close_standard',
			svg: `<path d="M18.4761 2.69878L16.6345 0.857143L9.33329 8.15837L2.03206 0.857143L0.19043 2.69878L7.49165 10L0.19043 17.3012L2.03206 
            19.1429L9.33329 11.8416L16.6345 19.1429L18.4761 17.3012L11.1749 10L18.4761 2.69878Z" fill='white' />`
		}
	};
	let displayIcon = icons[name];
</script>

<svg
	class={$$props.class}
	{focusable}
	{width}
	{height}
	viewBox="0 0 {displayIcon.box} {displayIcon.box}">{@html displayIcon.svg}</svg
>

<style>
</style>
