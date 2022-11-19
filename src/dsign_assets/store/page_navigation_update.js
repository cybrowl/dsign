import { page_navigation } from './page_navigation';

function select_item(num) {
	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[num].isSelected = true;

		return {
			navItems: navItems
		};
	});
}

export default {
	select_item
};
